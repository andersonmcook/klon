defmodule Klon do
  @external_resource Path.join([__DIR__, "../README.md"])

  @doc_header """
  Klon simplifies cloning of database records via Ecto with a simple API and flexible, user-defined protocol implementations.
  """

  @doc_footer @external_resource
              |> File.read!()
              |> String.split("<!-- MDOC -->")
              |> Enum.fetch!(1)

  @moduledoc @doc_header <> @doc_footer

  alias __MODULE__.{Clonable, Graph, Metadata}
  alias Ecto.Multi

  @doc """
  Returns a multi to clone a source and its child associations recursively.

  Parameters may be passed down to children using the association name.

  ## Examples

  No parameters:

      multi = Klon.clone(parent)

  With parameters:

      multi = Klon.clone(parent, %{example: 1})

  With parameters to children:

      multi = Klon.clone(parent, %{children: %{child_example: 2}, example: 2})
  """
  @spec clone(Clonable.t(), Clonable.params()) :: Multi.t()
  def clone(source, params \\ %{}) do
    [parent | children] =
      source
      |> Graph.new()
      |> :digraph_utils.topsort()

    Enum.reduce(
      [Metadata.new(parent, root: true) | Enum.map(children, &Metadata.new/1)],
      Multi.new(),
      & &1.strategy.clone(&1, &2, source, params)
    )
  end

  @doc false
  @spec params(Metadata.t(), map, map) :: map
  def params(metadata, assoc_params, changes) do
    parent_assoc = parent_assoc(metadata, assoc_params)

    parent =
      changes
      |> Map.fetch!(assoc_params.parent.name)
      |> Ecto.reset_fields(Map.keys(metadata.parent_assocs))

    Map.merge(
      %{
        assoc_params.parent.assoc => parent,
        parent_assoc.owner_key => Map.fetch!(parent, parent_assoc.related_key)
      },
      assoc_params.params
    )
  end

  defp parent_assoc(metadata, assoc_name) do
    Map.fetch!(metadata.parent_assocs, assoc_name.parent.assoc)
  end

  @doc false
  @spec multi(Clonable.t(), map, Metadata.t()) :: Multi.t()
  def multi(source, params, metadata) do
    name = name(source)
    {child_params, params} = Map.split(params, Map.keys(metadata.mapping))

    # Only query for assocs when the source is cloned
    source
    |> Clonable.multi(name, changeset(source, params, metadata))
    |> Multi.merge(fn
      %{^name => _} -> assocs_multi(source, name, child_params, metadata)
      _ -> Multi.new()
    end)
  end

  # Reset common fields and associations
  defp changeset(source, params, metadata) do
    source
    |> Ecto.put_meta(state: :built)
    |> Ecto.reset_fields(metadata.assocs)
    |> Clonable.changeset(params)
    |> reset_fields(metadata.reset_fields)
  end

  defp reset_fields(nil, _), do: nil

  defp reset_fields(changeset, reset_fields) do
    Map.update!(changeset, :data, &Ecto.reset_fields(&1, reset_fields))
  end

  # Query for associations to clone
  defp assocs_multi(source, name, params, metadata) do
    assoc_name = &assoc_name(metadata, &1, params, name)

    source
    |> Clonable.assocs()
    |> Enum.reduce(Multi.new(), &Multi.all(&2, assoc_name.(&1), Ecto.assoc(source, &1)))
  end

  # Name used to store associated records of a source
  defp assoc_name(metadata, assoc, params, parent_name) do
    child_assoc = Map.fetch!(metadata.mapping, assoc)
    {params, _} = Map.pop(params, assoc, %{})

    {__MODULE__,
     %{
       params: params,
       parent: %{assoc: child_assoc.field, name: parent_name},
       schema: child_assoc.owner
     }}
  end

  @opaque name :: {__MODULE__, module, Multi.name()}

  @doc """
  Returns the name of a source's clone in a multi's changes.
  """
  @spec name(source :: Clonable.t()) :: name
  def name(%module{} = schema) do
    {__MODULE__, module, Map.take(schema, module.__schema__(:primary_key))}
  end

  @doc """
  Returns a function to access a source's clone in an multi's changes.
  """
  @spec value(source :: t) :: (Multi.changes() -> clone :: nil | t) when t: Clonable.t()
  def value(source) do
    name = name(source)
    &Map.get(&1, name)
  end

  @doc """
  Returns a function to access a source's clone in an multi's changes.

  An exception is raised if the clone is not present.
  """
  @spec value!(source :: t) :: (Multi.changes() -> clone :: t) when t: Clonable.t()
  def value!(source) do
    name = name(source)
    &Map.fetch!(&1, name)
  end

  @doc """
  Returns a function to pair a source and its clone from an multi's changes.
  """
  @spec pair(source :: t) :: (Multi.changes() -> {source :: t, clone :: nil | t})
        when t: Clonable.t()
  def pair(source) do
    name = name(source)
    &{source, Map.get(&1, name)}
  end

  @doc """
  Returns a function to pair a source and its clone from an Multi's changes.

  An exception is raised if the clone is not present.
  """
  @spec pair!(source :: t) :: (Multi.changes() -> {source :: t, clone :: t}) when t: Clonable.t()
  def pair!(source) do
    name = name(source)
    &{source, Map.fetch!(&1, name)}
  end
end
