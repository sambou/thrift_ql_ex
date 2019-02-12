defmodule ThriftQlEx do
  @moduledoc """
  ThriftQlEx parses Thrift IDL into GraphQL SDL.
  """

  @doc """
  Parse.

  """
  defdelegate parse(doc), to: ThriftQlEx.Parser
end
