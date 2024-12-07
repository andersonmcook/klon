defmodule Klon.GraphTest do
  use ExUnit.Case, async: true

  alias Klon.{Dependent, Graph, Implemented, Normal, SelfReferential}

  test "builds a graph including self-referential schemas" do
    graph = Graph.new(%Implemented{})

    assert [Dependent, Implemented, Normal, SelfReferential] =
             graph |> :digraph.vertices() |> Enum.sort()

    assert [] = :digraph.in_neighbours(graph, Implemented)
    assert [SelfReferential, Normal] = :digraph.out_neighbours(graph, Implemented)
    assert [Dependent] = :digraph.out_neighbours(graph, SelfReferential)
    assert [Dependent] = :digraph.out_neighbours(graph, Normal)
    assert [] = :digraph.out_neighbours(graph, Dependent)
  end
end
