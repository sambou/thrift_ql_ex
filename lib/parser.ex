defmodule ThriftQlEx.Parser do
  @moduledoc false

  alias ThriftQlEx.Types, as: T

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

    %{
      "data" => %T.IntrospectionQuery{
        __schema: %T.IntrospectionSchema{
          queryType: %T.IntrospectionNamedTypeRef{name: "Query", kind: "OBJECT"},
          mutationType: nil,
          types: types,
          directives: []
        }
      }
    }
  end

  defp get_base_types(%Thrift.AST.Schema{enums: enums, structs: structs}) do
    gql_enums = enums |> Enum.map(fn {_, v} -> extract_enum(v) end)
    gql_types = structs |> Enum.map(fn {_, v} -> extract_object(v) end)
    types = gql_enums ++ gql_types

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

  ### Primitives

  # 'string' | 'binary' | 'slist'
  @spec extract_field(any) :: %T.IntrospectionField{} | %T.IntrospectionFieldReference{}
  defp extract_field(%Thrift.AST.Field{type: string_val, name: name})
       when string_val in [:string, :binary, :slist] do
    %T.IntrospectionField{name: name, type: %T.IntrospectionScalarType{name: "String"}}
  end

  # 'byte' | 'i8' | 'i16' | 'i32' | 'i64'
  defp extract_field(%Thrift.AST.Field{type: int_val, name: name})
       when int_val in [:byte, :i8, :i16, :i32, :i64] do
    %T.IntrospectionField{name: name, type: %T.IntrospectionScalarType{name: "Int"}}
  end

  # 'double'
  defp extract_field(%Thrift.AST.Field{type: :double, name: name}) do
    %T.IntrospectionField{name: name, type: %T.IntrospectionScalarType{name: "Float"}}
  end

  # 'bool'
  defp extract_field(%Thrift.AST.Field{type: :bool, name: name}) do
    %T.IntrospectionField{name: name, type: %T.IntrospectionScalarType{name: "Boolean"}}
  end

  ### List primitive types
  defp extract_field(%Thrift.AST.Field{
         type: %Thrift.AST.TypeRef{
           referenced_type: type
         },
         name: name
       }) do
    %T.IntrospectionFieldReference{name: name, referenced_type: type}
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {:list, string_val}
       })
       when string_val in [:string, :binary, :slist] do
    %T.IntrospectionField{
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionScalarType{name: "String"}
      }
    }
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {:list, float_val}
       })
       when float_val in [:double] do
    %T.IntrospectionField{
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionScalarType{name: "Float"}
      }
    }
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {:list, bool_val}
       })
       when bool_val in [:bool] do
    %T.IntrospectionField{
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionScalarType{name: "Boolean"}
      }
    }
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {:list, int_val}
       })
       when int_val in [:byte, :i8, :i16, :i32, :i64] do
    %T.IntrospectionField{
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionScalarType{name: "Int"}
      }
    }
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         type: {:list, %Thrift.AST.TypeRef{referenced_type: type}}
       }) do
    %T.IntrospectionField{
      args: [],
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionFieldReference{referenced_type: type}
      }
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
           {:list,
            %Thrift.AST.TypeRef{
              referenced_type: type
            }}
       }) do
    %T.IntrospectionField{
      args: Enum.map(params, &extract_input_field/1),
      name: name,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionFieldReference{referenced_type: type}
      }
    }
  end

  ### Input types
  # 'string' | 'binary' | 'slist'
  @spec extract_input_field(%Thrift.AST.Field{}) :: %T.IntrospectionInputValue{}
  defp extract_input_field(%Thrift.AST.Field{type: string_val, name: name})
       when string_val in [:string, :binary, :slist] do
    %T.IntrospectionInputValue{name: name, type: %T.IntrospectionScalarType{name: "String"}}
  end

  # 'byte' | 'i8' | 'i16' | 'i32' | 'i64'
  defp extract_input_field(%Thrift.AST.Field{type: int_val, name: name})
       when int_val in [:byte, :i8, :i16, :i32, :i64] do
    %T.IntrospectionInputValue{name: name, type: %T.IntrospectionScalarType{name: "Int"}}
  end

  # 'double'
  defp extract_input_field(%Thrift.AST.Field{type: :double, name: name}) do
    %T.IntrospectionInputValue{name: name, type: %T.IntrospectionScalarType{name: "Float"}}
  end

  # 'bool'
  defp extract_input_field(%Thrift.AST.Field{type: :bool, name: name}) do
    %T.IntrospectionInputValue{name: name, type: %T.IntrospectionScalarType{name: "Boolean"}}
  end

  defp extract_input_field(%Thrift.AST.Field{
         name: name,
         type: %Thrift.AST.TypeRef{
           referenced_type: type
         }
       }) do
    %T.IntrospectionInputValueReference{name: name, referenced_type: type}
  end
end
