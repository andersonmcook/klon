defmodule Klon.Dependent do
  @moduledoc """
  Represents a schema that depends on two parents to exist.
  """
  use Ecto.Schema

  alias Klon.{Normal, SelfReferential}

  @derive Klon.Clonable
  schema "dependents" do
    field :value, :string
    timestamps()
    belongs_to :normal, Normal
    belongs_to :self_referential, SelfReferential
  end
end
