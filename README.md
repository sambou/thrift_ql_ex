# ThriftQlEx

ThriftQlEx parses Thrift IDL into GraphQL SDL.

Usage:

```Elixir
ThriftQlEx.parse(thrift_schema)
```

Note: Currently, the library itself only parses Thrift IDL into the GraphQL JSON representation. The final transformation needs to be done with an external tool, checkout `schema.js` for a reference. Once support for JSON to GraphQL SDL lands in [Absinthe](https://github.com/absinthe-graphql/absinthe), this functionality will be provided out of the box.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `thrift_ql_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thrift_ql_ex, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/thrift_ql_ex](https://hexdocs.pm/thrift_ql_ex).
