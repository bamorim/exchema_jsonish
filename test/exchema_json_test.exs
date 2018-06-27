defmodule ExchemaJSONishTest do
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
  structure(StructureWithDateTime, [
    datetime: T.DateTime
  ])

  x = %{"map" => %{"a" => "a"}}
  ExchemaCoercion.coerce(x, Simple)

  property "we can coerce to valid JSONish all default Exchema Types" do
    check all value <- ExchemaStreamData.gen(Value) do
      value
      |> ExchemaJSONish.encode()
      |> Exchema.is?(ExchemaJSONish.JSONish)
      |> assert()
    end
  end

  property "we can bring it back to the struct when using default encodings and coercions" do
    check all value <- ExchemaStreamData.gen(Value) do
      errors =
        value
        |> ExchemaJSONish.encode()
        |> ExchemaCoercion.coerce(Value)
        |> Exchema.errors(Value)

      assert [] = errors
    end
  end

  describe "overriding encoding behaviour" do
    test "representing datetimes as integers" do
      struct = %StructureWithDateTime{datetime: DateTime.from_unix!(1000)}
      encoded = ExchemaJSONish.encode(
        struct,
        fn
          %DateTime{} -> &DateTime.to_unix/1
          _ -> nil
        end
      )

      assert %{"datetime" => 1000} = encoded

      assert struct == ExchemaCoercion.coerce(encoded, StructureWithDateTime)
    end
  end
end
