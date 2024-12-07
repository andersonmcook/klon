defmodule Klon.Test do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Klon.{Dependent, Implemented, Normal, Repo, SelfReferential, Unimplemented}

  setup do
    :ok = Sandbox.checkout(Repo)
  end

  test "name/1 returns the name of the cloned record" do
    normal = insert!(Normal)
    assert {:ok, changes} = clone(normal)
    assert normal.value == Map.fetch!(changes, Klon.name(normal)).value
  end

  test "value/1 returns a function to find a cloned record" do
    normal = insert!(Normal)
    assert {:ok, changes} = clone(normal)
    value_fn = Klon.value(normal)
    assert normal.value == value_fn.(changes).value
  end

  test "pair/1 returns a function to pair a source and clone" do
    normal = insert!(Normal)
    assert {:ok, changes} = clone(normal)
    pair_fn = Klon.pair(normal)
    assert {^normal, clone} = pair_fn.(changes)
    assert normal.value == clone.value
  end

  test "clones without params" do
    normal = insert!(Normal)
    assert {:ok, _} = clone(normal)

    assert Normal
           |> where([n], n.value == ^normal.value and n.id != ^normal.id)
           |> Repo.exists?()
  end

  test "clones with params" do
    normal = insert!(Normal, variant: :changeset)
    value = normal.value
    implemented = insert!(Implemented)
    assert {:ok, _} = clone(normal, %{implemented: implemented, variant: :assocs})

    assert %{value: "cloned " <> ^value, variant: :assocs} =
             implemented
             |> Ecto.assoc(:normals)
             |> Repo.one()
  end

  test "clones children" do
    implemented = insert!(Implemented)
    sort = fn list -> Enum.sort_by(list, & &1.value) end

    normals =
      1..3
      |> Enum.map(fn _ -> insert!(Normal, implemented: implemented, variant: :assocs) end)
      |> sort.()

    self_referentials =
      1..3
      |> Enum.map(fn _ -> insert!(SelfReferential, implemented: implemented) end)
      |> sort.()

    normals
    |> Enum.zip(self_referentials)
    |> Enum.map(fn {normal, self_referential} ->
      insert!(Dependent, normal: normal, self_referential: self_referential)
    end)

    assert {:ok, _} = clone(implemented)

    assert %{normals: [_, _, _], self_referentials: [_, _, _]} =
             clone =
             Implemented
             |> where([i], i.id != ^implemented.id and i.value == ^implemented.value)
             |> preload(normals: :dependents, self_referentials: :dependents)
             |> Repo.one()

    for {source, clone} <- Enum.zip(normals, sort.(clone.normals)) do
      [dependent] = clone.dependents
      assert clone.id == dependent.normal_id
      assert source.value == clone.value
    end

    for {source, clone} <- Enum.zip(self_referentials, sort.(clone.self_referentials)) do
      [dependent] = clone.dependents
      assert clone.id == dependent.self_referential_id
      assert source.value == clone.value
    end
  end

  test "does not clone children if source is not cloned" do
    normal = insert!(Normal, variant: :skip)
    self_referential = insert!(SelfReferential)
    insert!(Dependent, normal: normal, self_referential: self_referential)
    assert {:ok, _} = clone(normal)
    assert 1 = Repo.aggregate(Dependent, :count)
  end

  test "clones children with nested params" do
    implemented = insert!(Implemented)
    normal = insert!(Normal, implemented: implemented, variant: :assocs)

    insert!(Dependent,
      normal: normal,
      self_referential: insert!(SelfReferential, implemented: implemented)
    )

    assert {:ok, _} =
             clone(implemented, %{
               normals: %{dependents: %{value: "dependent"}, value: "normal"},
               value: "implemented"
             })

    assert %{
             normals: [%{dependents: [%{value: "dependent"}], value: "normal"}],
             value: "implemented"
           } =
             Implemented
             |> where([i], i.id != ^implemented.id)
             |> preload(normals: :dependents)
             |> Repo.one()
  end

  test "clones self-referential schemas" do
    implemented = insert!(Implemented)

    for _ <- 1..3 do
      self_referential_a = insert!(SelfReferential, implemented: implemented)

      for _ <- 1..3 do
        self_referential_b = insert!(SelfReferential, parent: self_referential_a)

        for _ <- 1..3 do
          insert!(SelfReferential, parent: self_referential_b)
        end
      end
    end

    assert {:ok, _} = clone(implemented)

    assert clone =
             Implemented
             |> where([i], i.id != ^implemented.id)
             |> preload(self_referentials: [children: :children])
             |> Repo.one()

    assert [_, _, _] = clone.self_referentials

    for parent <- clone.self_referentials do
      assert [_, _, _] = parent.children

      for child <- parent.children do
        assert [_, _, _] = child.children
        refute child.implemented_id

        for grandchild <- child.children do
          refute grandchild.implemented_id
        end
      end
    end
  end

  test "clones self-referential schemas starting with a self-referential schema" do
    implemented = insert!(Implemented)

    self_referential_a = insert!(SelfReferential, implemented: implemented)

    for _ <- 1..3 do
      self_referential_b = insert!(SelfReferential, parent: self_referential_a)

      for _ <- 1..3 do
        insert!(SelfReferential, parent: self_referential_b)
      end
    end

    value = Klon.value(self_referential_a)

    assert {:ok, changes} = clone(self_referential_a)

    assert clone =
             changes
             |> value.()
             |> Repo.preload(children: :children)

    assert [_, _, _] = clone.children

    for child <- clone.children do
      assert [_, _, _] = child.children
      refute child.implemented_id

      for grandchild <- child.children do
        refute grandchild.implemented_id
      end
    end
  end

  test "clones self-referential schemas with multiple parents" do
    implemented = insert!(Implemented)

    for _ <- 1..3 do
      self_referential_a =
        insert!(SelfReferential, implemented: implemented)

      for _ <- 1..3 do
        self_referential_b =
          insert!(SelfReferential, implemented: implemented, parent: self_referential_a)

        for _ <- 1..3 do
          insert!(SelfReferential, implemented: implemented, parent: self_referential_b)
        end
      end
    end

    assert {:ok, _} = clone(implemented)

    assert clone =
             Implemented
             |> where([i], i.id != ^implemented.id)
             |> preload(
               self_referentials:
                 ^{where(SelfReferential, [sr], is_nil(sr.parent_id)), [children: :children]}
             )
             |> Repo.one()

    assert [_, _, _] = clone.self_referentials

    for parent <- clone.self_referentials do
      assert [_, _, _] = parent.children
      refute parent.parent_id

      for child <- parent.children do
        assert [_, _, _] = child.children
        assert clone.id == child.implemented_id

        for grandchild <- child.children do
          assert clone.id == grandchild.implemented_id
        end
      end
    end
  end

  test "clones self-referential schemas with multiple parents starting with a self-referential schema" do
    implemented = insert!(Implemented)
    self_referential_a = insert!(SelfReferential, implemented: implemented)
    self_referential_b = insert!(SelfReferential, parent: self_referential_a)
    insert!(SelfReferential, parent: self_referential_b)
    assert {:ok, changes} = clone(self_referential_a)
    clone = Repo.preload(Klon.value(self_referential_a).(changes), children: :children)
    assert implemented.id == clone.implemented_id
    assert %{children: [%{children: [_]}]} = clone
  end

  test "preserves existing parent associations when a parent is not cloned" do
    implemented = insert!(Implemented)
    normal = insert!(Normal, implemented: implemented, variant: :assocs)
    self_referential = insert!(SelfReferential, implemented: implemented)
    dependent = insert!(Dependent, normal: normal, self_referential: self_referential)
    assert {:ok, changes} = clone(normal)
    clone = Klon.value(dependent).(changes)
    assert self_referential.id == clone.self_referential_id
    refute normal.id == clone.normal_id
  end

  test "clones when parent doesn't implement protocol" do
    implemented = insert!(Implemented)
    unimplemented = insert!(Unimplemented)
    normal = insert!(Normal, implemented: implemented)

    assert {:ok, _} = clone(normal, %{unimplemented: unimplemented})

    assert unimplemented
           |> Ecto.assoc(:normals)
           |> where(value: ^normal.value)
           |> Repo.exists?()
  end

  defp insert!(module, opts \\ []) do
    module
    |> struct!([{:value, Ecto.UUID.generate()} | opts])
    |> Repo.insert!()
  end

  defp clone(source, params \\ %{}) do
    source
    |> Klon.clone(params)
    |> Repo.transaction()
  end
end
