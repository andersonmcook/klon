# Klon

Klon simplifies cloning of database records via Ecto with a simple API and flexible, user-defined protocol implementations.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `klon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:klon, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/klon>.

<!-- MDOC -->

## Setup

Define an implementation for an `Ecto.Schema`.

```elixir
defmodule Parent do
  use Ecto.Schema

  defimpl Klon.Clonable do
    def assocs(_parent), do: ~w(children)a
    def change(parent, params), do: Ecto.Changset.change(parent, params)

    def multi(parent, name, changeset) do
      Ecto.Multi.insert(Ecto.Multi.new(), name, changeset)
    end
  end

  schema "parents" do
    field :example, :integer
    has_many :children, Child
  end
end
```

See `Klon.Clonable` for [documentation](lib/klon/clonable.ex) on implementations.

The protocol may instead be derived with zero or more options.
```elixir
defmodule Child do
  use Ecto.Schema

  @derive Klon.Clonable
  schema "children" do
    field :example, :integer

    belongs_to :parent, Parent
  end
end
```

### Options

- `:assocs` - A list of child associations to _always_ clone. Defaults to `[]`

- `:changeset` - A tuple of module and function that should return an `%Ecto.Changeset{}` or `nil`.
  Defaults to `{Ecto.Changeset, :change}`

## Usage

Clone the record.

```elixir
{:ok, changes} = source |> Klon.clone() |> Repo.transaction()
```

The clone may be accessed via the source in the changes:

```elixir
pair_fn = Klon.pair!(source)
value_fn = Klon.value!(source)
name = Klon.name(source)

{^source, clone} = pair_fn.(changes)
^clone = value_fn.(changes)
^clone = Map.fetch!(changes, name)
```

<!-- MDOC -->
