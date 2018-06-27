# ExchemaJSONish

Exchema JSONish provides a JSON-like Representation that is useful for Serialization/Deserialization
when used in conjunction with [ExchemaCoercion][exchema-coercion].

Why JSONish? Because the idea here is not to encode something to JSON, but instead to a intermediary
representation that is like JSON, but you could use to encode it to Messagepack, Avro, JSON, JSONB,
etc.

The idea is that JSONish is a datatype in Elixir that contains only the accepted types in JSON, that
is, a JSONish object can be either a string, a number, a map from string to JSONish or a list of
JSONish objects.

With this library you can encode all default Exchema types to that JSONish representation and then
you could use any encoder to transform it to a wire format.

That is also an Exchema Type that you can use to check if some value follows the JSONish
requirements.

## Basic Usage

```elixir
alias Exchema.Types, as: T
import Exchema.Notation

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

my_structure = %MyStructure{
  atom: :my_atom,
  boolean: true,
  date: Date.utc_today,
  datetime: DateTime.utc_now,
  float: 1.0,
  integer: 1,
  naive_datetime: NaiveDateTime.utc_now,
  number: 10.0,
  optional_atom: :another_atom,
  string: "my_string",
  time: Time.utc_now,
  recursion: nil
}

my_encoded_structure = my_structure |> ExchemaJSONish.encode()
%{
  "atom" => "my_atom",
  "boolean" => "true",
  "date" => "2018-06-26",
  "datetime" => "2018-06-26T20:38:36.953098Z",
  "float" => 1.0,
  "integer" => 1,
  "naive_datetime" => "2018-06-26T20:38:36.953104",
  "number" => 10.0,
  "optional_atom" => "another_atom",
  "recursion" => nil,
  "string" => "my_string",
  "time" => "20:38:36.953113"
}
```

### Checking if some map is a valid JSONish type

```elixir
my_encoded_structure |> Exchema.is?(ExchemaJSONish.JSONish) # true
%{"key": {:tuple, :here}} |> Exchema.is?(ExchemaJSONish.JSONish) # false
```

### Getting back to original

The idea is to use [ExchemaCoercion][exchema-coercion] to do that, so if your encoding have a
compatible coercion, everything should do ok. I did my best to make all encodings here match the
default coercions on [ExchemaCoercion][exchema-coercion].

However, if you override those you may run into trouble (so probably do property testing is a good
idea)

```elixir
my_encoded_structure |> ExchemaCoercion.coerce(MyStructure)
%MyStructure{
  atom: :my_atom,
  boolean: true,
  date: ~D[2018-06-26],
  datetime: #DateTime<2018-06-26 20:43:39.196687Z>,
  float: 1.0,
  integer: 1,
  naive_datetime: ~N[2018-06-26 20:43:39.199135],
  number: 10.0,
  optional_atom: :another_atom,
  recursion: nil,
  string: "my_string",
  time: ~T[20:43:39.200818]
}
```

### Overriding encodings

For now, instead of using protocols, I just enable you to pass a function that returns an encoding
function or nil if you don't want to override.

This is more general than a protocol since you can specify a override for a very specific value and
simpler. Maybe I'll change to a protocol later. This is also useful if you want to use another
encoding library.

```elixir
my_overrides = fn
  %DateTime{} -> &DateTime.to_unix/1
  _ -> nil
end

my_overriden_encoded_structure = my_structure |> ExchemaJSONish.encode(my_overrides)
%{
  "atom" => "my_atom",
  "boolean" => "true",
  "date" => "2018-06-26",
  "datetime" => 1530045819,
  "float" => 1.0,
  "integer" => 1,
  "naive_datetime" => "2018-06-26T20:43:39.199135",
  "number" => 10.0,
  "optional_atom" => "another_atom",
  "recursion" => nil,
  "string" => "my_string",
  "time" => "20:43:39.200818"
}
```

And since [ExchemaCoercion][exchema-coercion] already has a integer -> DateTime coercion using
from_unix, if you are using the defaults, you will not have any problems.

```elixir
my_overriden_encoded_structure |> ExchemaCoercion.coerce(MyStructure)
%MyStructure{
  atom: :my_atom,
  boolean: true,
  date: ~D[2018-06-26],
  datetime: #DateTime<2018-06-26 20:43:39Z>,
  float: 1.0,
  integer: 1,
  naive_datetime: ~N[2018-06-26 20:43:39.199135],
  number: 10.0,
  optional_atom: :another_atom,
  recursion: nil,
  string: "my_string",
  time: ~T[20:43:39.200818]
}
```

#### When to override

In general, It is useful to override when you have different types in a `OneOf`, and then sometimes
you'll want to encode with some special `type` field, so it serializes in a more explicit way.
However, you'll need to provide the appropriate coercion to [ExchemaCoercion][exchema-coercion]

## Installation

The package can be installed by adding `exchema_jsonish` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exchema_jsonish, "~> 0.1.0"}
  ]
end
```

[exchema-coercion]: https://github.com/bamorim/exchema_coercion