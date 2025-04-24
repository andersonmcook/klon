defprotocol Klon.Clonable do
  @moduledoc """
  A protocol to clone schemas and their child associations.

  ## Deriving

  The protocol may be derived with the following options: 

  - `:assocs` - A list of child associations to _always_ clone or a tuple of
  module and function that should return that list.

  - `:changeset` - A tuple of module and function that should return an
  `Ecto.Changeset` or `nil`.

  - `:multi` - A tuple of module and function that should return an `Ecto.Multi`. 

  See `Klon.Clonable.Default` for default implementations.

  ## Examples

  Using defaults:

  ```elixir
  @derive Klon.Clonable
  ```

  Specifying `assocs` only:

  ```elixir
  @derive {Klon.Clonable, assocs: ~w(children)a}
  ```

  Specifying all options:

  ```elixir
  @derive {Klon.Clonable,
           assocs: {__MODULE__, :assocs},
           changeset: {__MODULE__, :changeset},
           multi: {__MODULE__, :multi}}
  ```
  """

  alias Ecto.{Changeset, Multi, Schema}

  @fallback_to_any Application.compile_env(:klon, :allow_fallback_to_any, true)

  @typedoc """
  Parameters passed to `changeset/2`.
  """
  @type params :: %{optional(atom) => nil | t | Schema.t() | any}

  @doc """
  Lists child associations to load and clone.
  """
  @spec assocs(t) :: [atom]
  def assocs(source)

  @doc """
  Returns an `Ecto.Changeset` to use for the target record.

  Return `nil` to skip cloning.
  """
  @spec changeset(t, params) :: nil | Changeset.t()
  def changeset(source, params)

  @doc """
  Returns the entire `Ecto.Multi` containing any added operations.

  `changeset/2` has been been applied to the source, but the implementation should handle persistence.
  """
  @spec multi(t, Multi.name(), Changeset.t()) :: Multi.t()
  def multi(source, name, changeset)

  @impl Protocol
  defmacro __deriving__(module, opts) do
    opts =
      Keyword.validate!(
        opts,
        [
          :assocs,
          changeset: {__MODULE__.Default, :changeset},
          multi: {__MODULE__.Default, :multi}
        ]
      )

    delegate = &Enum.zip(~w(to as)a, Tuple.to_list(opts[&1]))

    assocs_definition =
      case Keyword.get(opts, :assocs, []) do
        {_, _} -> quote do: defdelegate(assocs(source), unquote(delegate.(:assocs)))
        assocs -> quote do: def(assocs(_source), do: unquote(assocs))
      end

    quote do
      defimpl Klon.Clonable, for: unquote(module) do
        unquote(assocs_definition)
        defdelegate changeset(source, params), unquote(delegate.(:changeset))
        defdelegate multi(source, name, changeset), unquote(delegate.(:multi))
      end
    end
  end
end
