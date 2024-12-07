defmodule Klon.SelfReferential do
  @moduledoc """
  Represents a schema that is self_referential.
  """

  alias Klon.{Clonable, Dependent, Implemented, SelfReferential, Unimplemented}

  use Ecto.Schema
  @derive {Clonable, assocs: ~w(children dependents)a}
  schema "self_referentials" do
    field :value, :string
    timestamps()
    belongs_to :implemented, Implemented
    belongs_to :parent, SelfReferential
    belongs_to :unimplemented, Unimplemented
    has_many :children, SelfReferential, foreign_key: :parent_id
    has_many :dependents, Dependent
  end
end
