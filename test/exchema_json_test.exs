defmodule ExchemaJSONTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Exchema.Types, as: T

  import Exchema.Notation

  subtype(MyAtom, T.Atom, [])

  structure(
    MyStructure,
    atom: T.Atom,
    boolean: T.Boolean,
    date: T.Date,
    datetime: T.DateTime,
    float: T.Float,
    integer: T.Integer,
    naive_datetime: T.NaiveDateTime,
    number: T.Number,
    optional_atom: {T.Optional, T.Atom},
    string: T.String,
    time: T.Time,
    recursion: {T.Optional, MyStructure}
  )

  structure(Simple, map: {T.Map, {T.Atom, T.Atom}})

  subtype(MyList, {T.List, T.Atom}, [])

  subtype(Structures, {T.OneStructOf, [MyStructure, Simple]}, [])
  subtype(Value, {T.OneOf, [MyAtom, MyList, Structures]}, [])
  x = %{"map" => %{"a" => "a"}}
  ExchemaCoercion.coerce(x, Simple)

  property "we can coerce to valid JSON all default Exchema Types" do
    check all value <- ExchemaStreamData.gen(Value) do
      value
      |> ExchemaJSON.encode()
      |> Exchema.is?(ExchemaJSON.JSON)
      |> assert()
    end
  end

  property "we can bring it back to the struct" do
    check all value <- ExchemaStreamData.gen(Value) do
      errors =
        value
        |> ExchemaJSON.encode()
        |> ExchemaCoercion.coerce(Value)
        |> Exchema.errors(Value)

      assert [] = errors
    end
  end

  def debug(value, key) do
    IO.inspect({key, value})
    value
  end
end
