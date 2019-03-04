defmodule ThriftQlEx.Printer do
  @moduledoc false

  alias ThriftQlEx.Types, as: T

  def print(%T.IntrospectionQuery{__schema: schema}) do
    {:ok,
     """
     schema {
     \tquery: #{schema.queryType.name}#{print_mutation(schema)}
     }

     #{print_types(schema.types) |> String.trim_trailing()}
     """}
  end

  defp print_types(types) do
    types
    |> Enum.map(fn
      %T.IntrospectionScalarType{name: name} ->
        "scalar #{name}\n\n"

      %T.IntrospectionEnumType{name: name, enumValues: enum_values} ->
        "enum #{name} {\n#{print_types(enum_values)}}\n\n"

      %T.IntrospectionEnumValue{name: name} ->
        "\t#{name}\n"

      %T.IntrospectionObjectType{name: name, fields: fields, interfaces: interfaces} ->
        "type #{name}#{print_interfaces(interfaces)} {\n#{print_types(fields)}}\n\n"

      %T.IntrospectionInterfaceType{name: name, fields: fields} ->
        "interface #{name} {\n#{print_types(fields)}}\n\n"

      %T.IntrospectionUnionType{name: name, possibleTypes: possibleTypes} ->
        "union #{name} = #{print_union_types(possibleTypes)}\n\n"

      %T.IntrospectionField{args: args, name: name, type: %{name: n}}
      when args != [] ->
        "\t#{name}#{print_args(args)}: #{n}\n"

      %T.IntrospectionField{name: name, type: %{name: n}} = field ->
        "\t#{name}: #{n}#{print_non_null(field)}\n"

      %T.IntrospectionField{
        args: args,
        name: name,
        type: %T.IntrospectionListTypeRef{ofType: %{name: n}}
      } = field
      when args != [] ->
        "\t#{name}#{print_args(args)}: [#{n}]#{print_non_null(field)}\n"

      %T.IntrospectionField{
        name: name,
        type: %T.IntrospectionListTypeRef{ofType: %{name: n}}
      } = field ->
        "\t#{name}: [#{n}]#{print_non_null(field)}\n"
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

  defp print_union_types(types) do
    types
    |> Enum.map(fn %T.IntrospectionField{type: %T.IntrospectionNamedTypeRef{name: name}} ->
      name
    end)
    |> Enum.join(" | ")
  end

  defp print_interfaces([]), do: ""

  defp print_interfaces(interfaces) do
    " implements #{Enum.join(interfaces, ", ")}"
  end

  defp print_non_null(%{required: true}), do: "!"
  defp print_non_null(_), do: ""

  defp print_mutation(%{mutationType: type}) when type != nil, do: "\n\tmutation: #{type.name}"
  defp print_mutation(_), do: ""
end
