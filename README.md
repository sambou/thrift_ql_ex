# ThriftQlEx

![Thrift to GraphQL](images/thrift_to_gql.png)

ThriftQlEx converts Thrift IDL into GraphQL SDL.

Usage:

```Elixir
 mix thrift_ql_ex.gen --thrift schema.thrift --out schema.graphql
```

## Installation

Add `thrift_ql_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:thrift_ql_ex, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) and published on [HexDocs](https://hexdocs.pm).The docs can be found at [https://hexdocs.pm/thrift_ql_ex](https://hexdocs.pm/thrift_ql_ex).

## Open topics

- [ ] handle Sets (treat as list)
- [ ] handle Maps
- [ ] handle Union -> consider dropping; create compound type
- [ ] handle optional / non optional fields
- [ ] deal with Services, Namespaces and naming conflicts
- [ ] include descriptions and deprecations
- [ ] implement directive for automatic resolution via Thrift client
