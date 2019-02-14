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

  def run(argv) do
    {parsed, _, _} = OptionParser.parse(argv, strict: [out: :string, thrift: :string])
    [out: out, thrift: thrift] = parsed

    with {:ok, thrift_schema} <- File.read(thrift),
         {:ok, json} <- ThriftQlEx.parse(thrift_schema),
         {:ok, sdl} <- ThriftQlEx.print(json),
         :ok <- File.write(out, sdl) do
      IO.puts("Schema created at #{out}")
    else
      e -> IO.inspect(e)
    end
  end
end
