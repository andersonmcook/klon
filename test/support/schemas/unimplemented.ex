defmodule Klon.Unimplemented do
  @moduledoc """
  Represents a parent schema that does not implement `Klon.Clonable`.
  """

  use Ecto.Schema

  alias Klon.{Normal, SelfReferential}

  schema "unimplementeds" do
    field :value, :string
    timestamps()
    has_many :normals, Normal
    has_many :self_referentials, SelfReferential
  end
end
