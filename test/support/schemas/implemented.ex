defmodule Klon.Implemented do
  @moduledoc """
  Represents a parent schema that implements `Klon.Clonable`.
  """

  use Ecto.Schema

  alias Klon.{Clonable, Normal, SelfReferential}

  @derive {Clonable, assocs: ~w(normals self_referentials)a}
  schema "implementeds" do
    field :value, :string
    timestamps()
    has_many :normals, Normal
    has_many :self_referentials, SelfReferential
  end
end
