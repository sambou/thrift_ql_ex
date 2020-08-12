defmodule ThriftQlEx.CLI do
  def thrift_to_graphql(args) when is_bitstring(args) do
    args
    |> OptionParser.split()
    |> thrift_to_graphql()
  end

  def thrift_to_graphql(args) do
    {parsed, _, _} = OptionParser.parse(args, strict: [out: :string, thrift: :string])
    out = Keyword.get(parsed, :out)
    thrift = Keyword.get(parsed, :thrift)

    with {:ok, thrift_schema} <- File.read(thrift),
         {:ok, json} <- ThriftQlEx.parse(thrift_schema),
         {:ok, sdl} <- ThriftQlEx.print(json),
         :ok <- File.write(out, sdl) do
      :ok
    else
      _ -> :error
    end
  end
end
