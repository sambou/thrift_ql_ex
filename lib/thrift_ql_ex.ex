defmodule ThriftQlEx do
  @moduledoc """
  ThriftQlEx parses Thrift IDL into GraphQL SDL.
  """

  alias ThriftQlEx.Types, as: T

  @doc ~S"""
  Parses a Thrift IDL string into a GraphQL JSON introspection query.
  """
  @spec parse(String.t()) :: {:ok, %T.IntrospectionQuery{__schema: term()}} | {:error, term()}
  defdelegate parse(thrift_schema), to: ThriftQlEx.Parser

  @doc ~S"""
  Takes a GraphQL JSON introspection query and prints a GraphQL SDL schema.
  """
  @spec print(%T.IntrospectionQuery{__schema: term()}) :: {:ok, String.t()} | {:error, term()}
  defdelegate print(introspection_query), to: ThriftQlEx.Printer
end
