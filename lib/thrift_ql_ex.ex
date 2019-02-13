defmodule ThriftQlEx do
  @moduledoc """
  ThriftQlEx parses Thrift IDL into GraphQL SDL.
  """

  @doc ~S"""
  Parses a Thrift IDL string into the GraphQL JSON representation.
  """
  @spec parse(String.t()) :: {:ok, %{data: %{__schema: term()}}} | {:error, term()}
  defdelegate parse(doc), to: ThriftQlEx.Parser
end
