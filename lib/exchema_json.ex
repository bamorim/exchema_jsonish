defmodule ExchemaJSON do
  @moduledoc """
  Documentation for ExchemaJSON.
  """

  alias ExchemaJSON.JSON

  def encode(nil), do: nil

  def encode(input) when is_atom(input),
    do: to_string(input)

  def encode(input) when is_number(input) or is_binary(input),
    do: input

  def encode(%mod{} = input)
      when mod in [DateTime, NaiveDateTime, Time, Date],
      do: mod.to_iso8601(input)

  def encode(%mod{} = input) do
    input
    |> Map.from_struct()
    |> encode()
  end

  def encode(%{} = input) do
    input
    |> Map.to_list()
    |> Enum.map(fn {k, v} -> {to_string(k), encode(v)} end)
    |> Enum.into(%{})
  end

  def encode(input) when is_list(input) do
    if Keyword.keyword?(input) and input != [] do
      input
      |> Enum.into(%{})
      |> encode()
    else
      input
      |> Enum.map(&encode/1)
    end
  end

  def encode(input) when is_tuple(input) do
    input
    |> Tuple.to_list()
    |> encode()
  end

  defmodule JSON do
    import Exchema.Notation
    alias Exchema.Types, as: T
    alias __MODULE__, as: JSON
    subtype(Object, {T.Map, {T.String, JSON}}, [])
    subtype(List, {T.List, JSON}, [])
    subtype(Nil, T.Atom, [{{Exchema.Predicates, :inclusion}, [nil]}])
    subtype(Value, {T.OneOf, [T.Number, T.String, Object, List, Nil]}, [])
    subtype({T.Optional, Value}, [])
  end
end
