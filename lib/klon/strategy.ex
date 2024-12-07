defmodule Klon.Strategy do
  @moduledoc false

  alias Ecto.Multi
  alias Klon.{Clonable, Metadata}

  @callback clone(Metadata.t(), Multi.t(), Clonable.t(), Clonable.params()) :: Multi.t()
end
