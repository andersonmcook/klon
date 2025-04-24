defmodule Klon.Normal do
  @moduledoc """
  Represents a schema that must have at least one parent and zero or many children.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Multi
  alias Klon.{Clonable, Dependent, Implemented, Unimplemented}

  defimpl Clonable do
    def assocs(%{variant: :assocs}), do: ~w(dependents)a
    # Tests that assocs are not cloned if the parent is not cloned
    def assocs(%{variant: :skip}), do: ~w(dependents)a
    def assocs(_), do: []

    def changeset(%{variant: :changeset} = source, params) do
      source
      |> change(params)
      |> change(%{value: "cloned #{source.value}"})
    end

    def changeset(%{variant: :skip}, _), do: nil
    def changeset(source, params), do: change(source, params)

    def multi(%{variant: :skip}, _, _), do: Multi.new()
    defdelegate multi(source, name, changeset), to: Clonable.Default
  end

  schema "normals" do
    field :value, :string
    field :variant, Ecto.Enum, values: ~w(assocs changeset skip)a
    timestamps()
    belongs_to :implemented, Implemented
    belongs_to :unimplemented, Unimplemented
    has_many :dependents, Dependent
  end
end
