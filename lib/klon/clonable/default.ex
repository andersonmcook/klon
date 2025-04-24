defmodule Klon.Clonable.Default do
  @moduledoc """
  A default implementation of the `Klon.Clonable` protocol.
  """

  alias Ecto.{Changeset, Multi}

  @doc """
  Returns an empty list of associations.
  """
  def assocs(_source), do: []

  @doc """
  Applies all parameters as changes.
  """
  def changeset(source, params), do: Changeset.change(source, params)

  @doc """
  Returns a multi with a step to insert a clone if a changeset is present or
  an empty multi if not.
  """
  def multi(_source, _name, nil), do: Multi.new()
  def multi(_source, name, changeset), do: Multi.insert(Multi.new(), name, changeset)
end
