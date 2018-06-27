defmodule ExchemaJSONish do
  @moduledoc """
  Documentation for ExchemaJSONish.
  """

  alias ExchemaJSONish.JSONish

  def encode(value, overrides \\ &(&1)) do
    case overrides.(value) do
      fun when is_function(fun, 1) ->
        fun.(value)
      _ ->
        do_encode(value, overrides)
    end
  end

  defp do_encode(nil, overrides), do: nil

  defp do_encode(input, overrides) when is_atom(input),
    do: to_string(input)

  defp do_encode(input, overrides) when is_number(input) or is_binary(input),
    do: input

  defp do_encode(%mod{} = input, overrides)
      when mod in [DateTime, NaiveDateTime, Time, Date],
      do: mod.to_iso8601(input)

  defp do_encode(%mod{} = input, overrides) do
    input
    |> Map.from_struct()
    |> encode(overrides)
  end

  defp do_encode(%{} = input, overrides) do
    input
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {to_string(k), encode(v, overrides)} end)
    |> Enum.into(%{})
  end

  defp do_encode(input, overrides) when is_list(input) do
    if Keyword.keyword?(input) and input != [] do
      input
      |> Enum.into(%{})
      |> encode(overrides)
    else
      input
      |> Enum.map(&encode/1)
    end
  end

  defp do_encode(input, overrides) when is_tuple(input) do
    input
    |> Tuple.to_list()
    |> encode(overrides)
  end

  defp do_encode(input, _), do: input

  defmodule JSONish do
    import Exchema.Notation
    alias Exchema.Types, as: T
    alias __MODULE__, as: JSONish
    subtype(Object, {T.Map, {T.String, JSONish}}, [])
    subtype(List, {T.List, JSONish}, [])
    subtype(Nil, T.Atom, [{{Exchema.Predicates, :inclusion}, [nil]}])
    subtype(Value, {T.OneOf, [T.Number, T.String, Object, List, Nil]}, [])
    subtype({T.Optional, Value}, [])
  end
end
