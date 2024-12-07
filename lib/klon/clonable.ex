defprotocol Klon.Clonable do
  @moduledoc """
  A protocol to clone schemas and their child associations.
  """

  alias Ecto.{Changeset, Multi, Schema}

  @fallback_to_any true

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
  Returns a changeset to use for the target record.

  Return `nil` to skip cloning.
  """
  @spec changeset(t, params) :: nil | Changeset.t()
  def changeset(source, params)

  @doc """
  Returns the entire multi containing any added operations.

  `changeset/2` has been been applied to the source, but the implementation should handle persistence.
  """
  @spec multi(t, Multi.name(), Changeset.t()) :: Multi.t()
  def multi(source, name, changeset)
end

defmodule Klon.Clonable.Default do
  @moduledoc false

  alias Ecto.Multi

  def assocs(_source), do: []

  def changeset(source, _params) do
    raise Protocol.UndefinedError,
      description: "`#{Klon.Clonable}.changeset/2` must be explicitly implemented",
      protocol: Klon.Clonable,
      value: source
  end

  def multi(_source, _name, nil), do: Multi.new()
  def multi(_source, name, changeset), do: Multi.insert(Multi.new(), name, changeset)
end

if Application.compile_env(:klon, :define_fallback_to_any, true) do
  defimpl Klon.Clonable, for: Any do
    alias Ecto.Changeset
    alias Klon.Clonable.Default

    defmacro __deriving__(module, _struct, opts) do
      opts = Keyword.validate!(opts, assocs: [], changeset: {Changeset, :change})
      delegate = Enum.zip(~w(to as)a, Tuple.to_list(opts[:changeset]))

      quote do
        defimpl Klon.Clonable, for: unquote(module) do
          def assocs(_source), do: unquote(opts[:assocs])
          defdelegate changeset(source, params), unquote(delegate)
          defdelegate multi(source, name, changeset), to: Default
        end
      end
    end

    defdelegate assocs(source), to: Default
    defdelegate changeset(source, params), to: Default
    defdelegate multi(source, name, changeset), to: Default
  end
end
