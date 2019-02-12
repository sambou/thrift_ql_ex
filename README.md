# ThriftQlEx

ThriftQlEx parses Thrift IDL into GraphQL SDL.

Usage:

```Elixir
ThriftQlEx.parse(thrift_schema)
```

Note: Currently, the library itself only parses Thrift IDL into the GraphQL JSON representation. The final transformation needs to be done with an external tool, checkout `schema.js` for a reference. Once support for JSON to GraphQL SDL lands in [Absinthe](https://github.com/absinthe-graphql/absinthe), this functionality will be provided out of the box.

## Installation

Add `thrift_ql_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thrift_ql_ex, github: "sambou/thrift_ql_ex"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/thrift_ql_ex](https://hexdocs.pm/thrift_ql_ex).

## Open topics

- [ ] handle Sets (treat as list)
- [ ] handle Maps
- [ ] handle Union -> consider dropping; create compound type
- [ ] handle optional / non optional fields
- [ ] deal with Services, Namespaces and naming conflicts
- [ ] transform JSON -> SDL
- [ ] include descriptions and deprecations
- [ ] implement directive for automatic resolution via Thrift client
