defmodule Mix.Tasks.ThriftQlEx.Gen do
  use Mix.Task

  @moduledoc """
  Generate a GraphQL SDL schema file from a Thrift file.

  ## Usage
    thriftql.gen [FILENAME] [OPTIONS]

  ## OPTIONS

  * `--thrift` - The file name of the Thrift schema
  * `--out` - The file name of the output SDL schema
  """

  def run(args) do
    with :ok <- ThriftQlEx.thrift_to_graphql(args) do
      IO.puts("Schema successfully created.")
    else
      e -> e
    end
  end
end
