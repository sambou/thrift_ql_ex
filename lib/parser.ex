defmodule ThriftQlEx.Parser do
  @moduledoc false

  alias ThriftQlEx.Types, as: T

  @list_like [:list, :set]
  @string_like [:string, :binary, :slist]
  @int_like [:byte, :i8, :i16, :i32, :i64]
  @bool_like [:bool]
  @float_like [:double]
  @id_like [:id, :Id, :iD, :ID]

  @scalars @string_like ++ @int_like ++ @float_like ++ @bool_like

  def parse(doc) do
    case Thrift.Parser.parse_string(doc) do
      {:ok, schema} ->
        {:ok, parse_schema(schema)}

      e ->
        e
    end
  end

  defp parse_schema(%Thrift.AST.Schema{} = schema) do
    types = get_base_types(schema) |> add_query(schema)

    %T.IntrospectionQuery{
      __schema: %T.IntrospectionSchema{
        queryType: %T.IntrospectionNamedTypeRef{name: "Query", kind: "OBJECT"},
        mutationType: nil,
        types: types,
        directives: []
      }
    }
  end

  defp get_base_types(%Thrift.AST.Schema{enums: enums, structs: structs, typedefs: typedefs}) do
    gql_enums = enums |> Enum.map(fn {_, v} -> extract_enum(v) end)
    gql_types = structs |> Enum.map(fn {_, v} -> extract_object(v) end)
    gql_scalars = typedefs |> extract_scalars()
    types = gql_enums ++ gql_types ++ gql_scalars

    resolve_referenced_types(types, types)
  end

  defp add_query(base_types, %Thrift.AST.Schema{services: services}) do
    gql_queries = services |> Enum.map(fn {_, v} -> extract_schema(v) end) |> List.flatten()
    query_fields = resolve_referenced_types(gql_queries, base_types)

    [
      %T.IntrospectionObjectType{
        name: "Query",
        fields: query_fields
      }
      | base_types
    ]
  end

  defp resolve_referenced_types(unresolved_types, types) do
    unresolved_types
    |> Enum.map(fn
      %T.IntrospectionField{
        args: args,
        type:
          %T.IntrospectionListTypeRef{ofType: %T.IntrospectionFieldReference{} = ref} = list_ref
      } = field ->
        %T.IntrospectionField{
          field
          | args: resolve_input_field_reference(args, types),
            type: %T.IntrospectionListTypeRef{list_ref | ofType: resolve_reference(ref, types)}
        }

      %T.IntrospectionField{type: %T.IntrospectionFieldReference{}} = type ->
        replace_reference_type(type, types)

      %T.IntrospectionObjectType{fields: fields} = object ->
        %T.IntrospectionObjectType{
          object
          | fields: resolve_referenced_fields(fields, types)
        }

      %ThriftQlEx.Types.IntrospectionEnumType{} = t ->
        t

      t ->
        t
    end)
  end

  defp resolve_referenced_fields(fields, types) do
    fields
    |> Enum.map(fn
      %T.IntrospectionFieldReference{} = field ->
        %T.IntrospectionField{
          name: field.name,
          type: resolve_reference(field, types)
        }

      %T.IntrospectionField{
        args: args,
        type:
          %T.IntrospectionListTypeRef{ofType: %T.IntrospectionFieldReference{} = ref} = list_ref
      } = field ->
        %T.IntrospectionField{
          field
          | args: resolve_input_field_reference(args, types),
            type: %T.IntrospectionListTypeRef{list_ref | ofType: resolve_reference(ref, types)}
        }

      t ->
        t
    end)
  end

  defp replace_reference_type(
         %T.IntrospectionField{
           args: args,
           type: %T.IntrospectionFieldReference{} = ref
         } = field,
         types
       ) do
    %T.IntrospectionField{
      field
      | args: resolve_input_field_reference(args, types),
        type: resolve_reference(ref, types)
    }
  end

  defp resolve_input_field_reference(args, types) do
    Enum.map(args, fn
      %T.IntrospectionInputValueReference{} = field ->
        %T.IntrospectionInputValue{type: resolve_reference(field, types), name: field.name}

      y ->
        y
    end)
  end

  defp resolve_reference(%{referenced_type: t}, _types) when t in @id_like do
    %T.IntrospectionScalarType{name: "ID"}
  end

  defp resolve_reference(%{referenced_type: type}, types) do
    t = Enum.find(types, fn %{name: name} -> name == type end)
    %T.IntrospectionNamedTypeRef{name: t.name, kind: t.kind}
  end

  @spec extract_enum(%Thrift.AST.TEnum{}) :: %T.IntrospectionEnumType{}
  defp extract_enum(%Thrift.AST.TEnum{name: name, values: values}) do
    enumValues = values |> Enum.map(fn {v, _} -> %T.IntrospectionEnumValue{name: v} end)

    %T.IntrospectionEnumType{name: name, enumValues: enumValues}
  end

  @spec extract_object(%Thrift.AST.Struct{}) :: %T.IntrospectionObjectType{}
  defp extract_object(%Thrift.AST.Struct{name: name, fields: fields}) do
    %T.IntrospectionObjectType{
      name: name,
      fields: Enum.map(fields, &extract_field/1)
    }
  end

  @spec extract_schema(%Thrift.AST.Service{}) :: list(%T.IntrospectionField{})
  defp extract_schema(%Thrift.AST.Service{functions: fns}) do
    fns |> Enum.map(fn {_, v} -> extract_field(v) end)
  end

  defp extract_scalars(scalars) do
    scalars
    |> Enum.map(fn
      {k, _} when k in @id_like -> nil
      {k, v} when v in @scalars -> %T.IntrospectionScalarType{name: k}
    end)
    |> Enum.filter(& &1)
  end

  ### Primitives

  @spec extract_field(any) :: %T.IntrospectionField{} | %T.IntrospectionFieldReference{}
  defp extract_field(%Thrift.AST.Field{type: val, name: name})
       when val in @scalars do
    %T.IntrospectionField{name: name, type: convert_scalar(val)}
  end

  defp extract_field(%Thrift.AST.Field{
         type: %Thrift.AST.TypeRef{
           referenced_type: type
         },
         name: name
       }) do
    %T.IntrospectionFieldReference{name: name, referenced_type: type}
  end

  ### List-likes

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {container, val}
       })
       when val in @scalars and container in @list_like do
    %T.IntrospectionField{
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: convert_scalar(val)
      }
    }
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {container, %Thrift.AST.TypeRef{referenced_type: type}}
       })
       when container in @list_like do
    %T.IntrospectionField{
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionFieldReference{referenced_type: type}
      }
    }
  end

  defp extract_field(%Thrift.AST.Function{
         name: name,
         return_type: val
       })
       when val in @scalars do
    %T.IntrospectionField{
      name: name,
      type: convert_scalar(val)
    }
  end

  defp extract_field(%Thrift.AST.Function{
         name: name,
         params: params,
         return_type: %Thrift.AST.TypeRef{
           referenced_type: type
         }
       }) do
    %T.IntrospectionField{
      args: Enum.map(params, &extract_input_field/1),
      name: name,
      type: %T.IntrospectionFieldReference{referenced_type: type}
    }
  end

  defp extract_field(%Thrift.AST.Function{
         name: name,
         params: params,
         return_type:
           {container,
            %Thrift.AST.TypeRef{
              referenced_type: type
            }}
       })
       when container in @list_like do
    %T.IntrospectionField{
      args: Enum.map(params, &extract_input_field/1),
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionFieldReference{referenced_type: type}
      }
    }
  end

  ### Input types
  @spec extract_input_field(%Thrift.AST.Field{}) :: %T.IntrospectionInputValue{}
  defp extract_input_field(%Thrift.AST.Field{type: val, name: name})
       when val in @scalars do
    %T.IntrospectionInputValue{name: name, type: convert_scalar(val)}
  end

  defp extract_input_field(%Thrift.AST.Field{
         name: name,
         type: %Thrift.AST.TypeRef{
           referenced_type: type
         }
       }) do
    %T.IntrospectionInputValueReference{name: name, referenced_type: type}
  end

  ### Utils
  defp convert_scalar(s) when s in @string_like, do: %T.IntrospectionScalarType{name: "String"}
  defp convert_scalar(s) when s in @int_like, do: %T.IntrospectionScalarType{name: "Int"}
  defp convert_scalar(s) when s in @float_like, do: %T.IntrospectionScalarType{name: "Float"}
  defp convert_scalar(s) when s in @bool_like, do: %T.IntrospectionScalarType{name: "Boolean"}
end
