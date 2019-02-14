defmodule ThriftQlEx.Printer do
  @moduledoc false

  alias ThriftQlEx.Types, as: T

  def print(%T.IntrospectionQuery{__schema: schema}) do
    {:ok,
     """
     schema {\n\tquery: #{schema.queryType.name}\n}

     #{print_types(schema.types) |> String.trim_trailing()}
     """}
  end

  defp print_types(types) do
    types
    |> Enum.map(fn
      %T.IntrospectionEnumType{name: name, enumValues: enum_values} ->
        "enum #{name} {\n#{print_types(enum_values)}}\n\n"

      %T.IntrospectionEnumValue{name: name} ->
        "\t#{name}\n"

      %T.IntrospectionObjectType{name: name, fields: fields} ->
        "type #{name} {\n#{print_types(fields)}}\n\n"

      %T.IntrospectionField{args: args, name: name, type: %{name: n}}
      when args != [] ->
        "\t#{name}#{print_args(args)}: #{n}\n"

      %T.IntrospectionField{name: name, type: %{name: n}} ->
        "\t#{name}: #{n}\n"

      %T.IntrospectionField{
        args: args,
        name: name,
        type: %T.IntrospectionListTypeRef{
          ofType: %{name: n}
        }
      }
      when args != [] ->
        "\t#{name}#{print_args(args)}: [#{n}]\n"

      %T.IntrospectionField{
        name: name,
        type: %T.IntrospectionListTypeRef{
          ofType: %{name: n}
        }
      } ->
        "\t#{name}: [#{n}]\n"
    end)
    |> Enum.join("")
  end

  defp print_args(args) do
    a =
      args
      |> Enum.map(fn
        %T.IntrospectionInputValue{
          name: name,
          type: %{name: n}
        } ->
          "#{name}: #{n}"
      end)
      |> Enum.join(", ")

    "(#{a})"
  end
end
