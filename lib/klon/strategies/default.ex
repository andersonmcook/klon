defmodule Klon.Strategies.Default do
  @moduledoc """
  A strategy for cloning non-self-referential schema records.
  """

  @behaviour Klon.Strategy

  alias Ecto.Multi

  @impl Klon.Strategy
  def clone(%{root: false, schema: schema} = metadata, multi, _, _) do
    Multi.merge(multi, fn changes ->
      params = &Klon.params(metadata, &1, changes)

      changes
      |> Enum.flat_map(fn
        {{_, %{schema: ^schema} = name}, [_ | _] = sources} ->
          params = params.(name)
          Enum.map(sources, &%{params: params, source: &1})

        _ ->
          []
      end)
      |> Enum.group_by(& &1.source, & &1.params)
      |> Enum.reduce(Multi.new(), fn {source, params_list}, multi ->
        params = Enum.reduce(params_list, %{}, &Map.merge/2)
        Multi.append(multi, Klon.multi(source, params, metadata))
      end)
    end)
  end

  # Root
  def clone(metadata, multi, source, params) do
    Multi.append(multi, Klon.multi(source, params, metadata))
  end
end
