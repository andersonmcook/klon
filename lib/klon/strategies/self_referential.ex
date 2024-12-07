defmodule Klon.Strategies.SelfReferential do
  @moduledoc """
  A strategy for cloning self-referential schemas.
  """

  @behaviour Klon.Strategy

  alias Ecto.Multi

  @impl Klon.Strategy
  # First clone self-referential schemas with no self-referential parent association
  def clone(%{root: false} = metadata, multi, _source, _params) do
    Multi.merge(
      multi,
      &clone(metadata, %{acc(metadata) | changes: &1, unresolved: unresolved(metadata, &1)})
    )
  end

  # Root
  def clone(metadata, multi, source, params) do
    name = Klon.name(source)

    multi
    |> Multi.append(Klon.multi(source, params, metadata))
    |> Multi.merge(fn
      %{^name => _} = changes ->
        clone(metadata, %{
          acc(metadata)
          | changes: changes,
            resolved: MapSet.new([name]),
            unresolved: unresolved(name, changes)
        })

      _ ->
        Multi.new()
    end)
  end

  defp acc(metadata) do
    %{
      changes: %{},
      halted: false,
      resolvable?: resolvable?(metadata),
      resolved: MapSet.new(),
      unresolved: MapSet.new()
    }
  end

  # Parents have been cloned.
  defp unresolved(%{schema: schema}, changes) do
    for {{_, %{schema: ^schema}}, [_ | _] = sources} <- changes,
        source <- sources,
        into: MapSet.new() do
      Klon.name(source)
    end
  end

  # Root source has been cloned.
  defp unresolved(name, changes) do
    for {{_, %{parent: %{name: ^name}}}, [_ | _] = sources} <- changes,
        source <- sources,
        into: MapSet.new() do
      Klon.name(source)
    end
  end

  defp clone(_metadata, acc) when acc.halted, do: Multi.new()

  defp clone(%{schema: schema} = metadata, acc) do
    changes = acc.changes
    params_fn = &Klon.params(metadata, &1, changes)

    resolvable =
      for {{_, %{schema: ^schema} = assoc_name}, [_ | _] = sources} <- changes,
          source <- sources,
          name = Klon.name(source),
          name in acc.unresolved do
        %{name: name, params: params_fn.(assoc_name), source: source}
      end

    {resolvable, unresolved} =
      resolvable
      |> Enum.group_by(& &1.name, &Map.take(&1, ~w(params source)a))
      |> Enum.map(fn {name, data} ->
        {name,
         %{params: Enum.reduce(data, %{}, &Map.merge(&1.params, &2)), source: hd(data).source}}
      end)
      |> Enum.reject(fn {name, _} -> name in acc.resolved end)
      |> Enum.split_with(fn {_, data} -> acc.resolvable?.(data.source, data.params) end)

    resolved =
      resolvable
      |> MapSet.new(&elem(&1, 0))
      |> MapSet.union(acc.resolved)

    resolvable
    |> Enum.reduce(Multi.new(), fn {_, data}, multi ->
      Multi.append(multi, Klon.multi(data.source, data.params, metadata))
    end)
    |> Multi.merge(fn changes ->
      changes = Map.merge(changes, acc.changes)

      unresolved =
        unresolved
        |> MapSet.new(&elem(&1, 0))
        |> MapSet.union(acc.unresolved)
        |> MapSet.union(unresolved(metadata, changes))
        |> MapSet.difference(resolved)

      clone(metadata, %{
        acc
        | changes: Map.merge(changes, acc.changes),
          halted: Enum.empty?(unresolved),
          resolved: resolved,
          unresolved: unresolved
      })
    end)
  end

  # Heuristic: A source can be cloned because its self-referential fields
  # are in the params, missing, or not loaded.
  defp resolvable?(metadata) do
    fn source, params ->
      Enum.all?(metadata.self_referential_fields, fn field ->
        source_value = Map.fetch!(source, field)

        Map.has_key?(params, field) or is_nil(source_value) or
          is_struct(source_value, Ecto.Association.NotLoaded)
      end)
    end
  end
end
