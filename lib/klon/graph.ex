defmodule Klon.Graph do
  @moduledoc false

  alias Ecto.Schema
  alias Klon.Clonable

  @doc false
  @spec new(Schema.t()) :: :digraph.graph()
  def new(%schema{}) do
    graph = :digraph.new([:acyclic])
    :digraph.add_vertex(graph, schema)
    build(graph, schema)
  end

  defp build(graph, parent) do
    for {_, {:assoc, assoc}} <- parent.__changeset__(),
        assoc.relationship == :child,
        Clonable.impl_for(struct(assoc.related)) do
      next(graph, parent, assoc.related)
    end

    graph
  end

  defp next(graph, parent, child) do
    if :digraph.vertex(graph, child) do
      :digraph.add_edge(graph, parent, child)
    else
      :digraph.add_vertex(graph, child)
      :digraph.add_edge(graph, parent, child)
      build(graph, child)
    end
  end
end
