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
    types = schema |> get_base_types() |> add_query(schema) |> add_mutation(schema)
    mutation = types |> Enum.find(fn x -> x.name == "Mutation" end)

    %T.IntrospectionQuery{
      __schema: %T.IntrospectionSchema{
        queryType: %T.IntrospectionNamedTypeRef{name: "Query", kind: "OBJECT"},
        mutationType: mutation,
        types: types,
        directives: []
      }
    }
  end

  defp get_base_types(%Thrift.AST.Schema{
         enums: enums,
         structs: structs,
         typedefs: typedefs,
         unions: unions
       }) do
    gql_enums = enums |> Enum.map(fn {_, v} -> extract_enum(v) end)
    gql_types = structs |> Enum.map(fn {_, v} -> extract_object(v) end)
    gql_scalars = typedefs |> extract_scalars()

    qql_unions =
      unions |> Enum.map(fn {_, v} -> extract_unions(v) end) |> Enum.filter(fn x -> x != nil end)

    types = gql_enums ++ gql_types ++ gql_scalars ++ qql_unions

    resolve_referenced_types(types, types)
  end

  defp add_query(base_types, %Thrift.AST.Schema{services: services}) do
    gql_queries =
      services
      |> Enum.map(fn {_, %Thrift.AST.Service{functions: fns}} ->
        fns |> Enum.map(fn {_, v} -> v end)
      end)
      |> List.flatten()
      |> Enum.filter(fn
        %{annotations: %{query: _}} -> true
        %{annotations: %{iface: _}} -> true
        %{annotations: %{query: _, iface: _}} -> true
        %{annotations: x} when x == %{} -> true
        _ -> false
      end)
      |> Enum.map(&extract_field/1)

    query_fields = resolve_referenced_types(gql_queries, base_types)

    [
      %T.IntrospectionObjectType{
        name: "Query",
        fields: query_fields
      }
      | base_types
    ]
  end

  defp add_mutation(base_types, %Thrift.AST.Schema{services: services}) do
    gql_mutations =
      services
      |> Enum.map(fn {_, %Thrift.AST.Service{functions: fns}} ->
        fns |> Enum.map(fn {_, v} -> v end)
      end)
      |> List.flatten()
      |> Enum.filter(fn
        %{annotations: %{mutation: _}} -> true
        %{annotations: %{mutation: _, iface: _}} -> true
        _ -> false
      end)
      |> Enum.map(&extract_field/1)

    case resolve_referenced_types(gql_mutations, base_types) do
      [] ->
        base_types

      mutation_fields ->
        [
          %T.IntrospectionObjectType{
            name: "Mutation",
            fields: mutation_fields
          }
          | base_types
        ]
    end
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

      %T.IntrospectionUnionType{possibleTypes: possible_types} = union ->
        %T.IntrospectionUnionType{
          union
          | possibleTypes: resolve_referenced_fields(possible_types, types)
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
          required: field.required,
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
    enum_values = values |> Enum.map(fn {v, _} -> %T.IntrospectionEnumValue{name: v} end)

    %T.IntrospectionEnumType{name: name, enumValues: enum_values}
  end

  @spec extract_object(%Thrift.AST.Struct{}) :: %T.IntrospectionObjectType{}
  defp extract_object(%Thrift.AST.Struct{
         annotations: %{iface: _},
         name: name,
         fields: fields
       }) do
    %T.IntrospectionInterfaceType{
      name: name,
      fields: Enum.map(fields, &extract_field/1)
    }
  end

  defp extract_object(%Thrift.AST.Struct{
         annotations: %{impl: implements},
         name: name,
         fields: fields
       }) do
    %T.IntrospectionObjectType{
      name: name,
      fields: Enum.map(fields, &extract_field/1),
      interfaces: implements |> String.split(",") |> Enum.map(&String.trim/1)
    }
  end

  defp extract_object(%Thrift.AST.Struct{
         name: name,
         fields: fields
       }) do
    %T.IntrospectionObjectType{
      name: name,
      fields: Enum.map(fields, &extract_field/1)
    }
  end

  defp extract_scalars(scalars) do
    scalars
    |> Enum.map(fn
      {k, _} when k in @id_like -> nil
      {k, v} when v in @scalars -> %T.IntrospectionScalarType{name: k}
    end)
    |> Enum.filter(& &1)
  end

  defp extract_unions(%Thrift.AST.Union{annotations: %{gql_ignore: _}}) do
    nil
  end

  defp extract_unions(%Thrift.AST.Union{name: name, fields: fields}) do
    %T.IntrospectionUnionType{
      name: name,
      possibleTypes: Enum.map(fields, &extract_field/1)
    }
  end

  ### Primitives

  @spec extract_field(any) :: %T.IntrospectionField{} | %T.IntrospectionFieldReference{}
  defp extract_field(%Thrift.AST.Field{type: type, name: name, required: required})
       when type in @scalars do
    %T.IntrospectionField{name: name, type: convert_scalar(type), required: required}
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         required: required,
         type: %Thrift.AST.TypeRef{referenced_type: type}
       })
       when type in @id_like do
    %T.IntrospectionField{name: name, type: convert_scalar(type), required: required}
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         required: required,
         type: %Thrift.AST.TypeRef{referenced_type: type}
       }) do
    %T.IntrospectionFieldReference{name: name, referenced_type: type, required: required}
  end

  ### List-likes

  defp extract_field(%Thrift.AST.Field{
         name: name,
         required: required,
         type: {container, val}
       })
       when (val in @scalars or val in @id_like) and container in @list_like do
    %T.IntrospectionField{
      name: name,
      required: required,
      type: %T.IntrospectionListTypeRef{ofType: convert_scalar(val)}
    }
  end

  defp extract_field(%Thrift.AST.Field{
         name: name,
         required: required,
         type: {container, %Thrift.AST.TypeRef{referenced_type: type}}
       })
       when container in @list_like do
    %T.IntrospectionField{
      name: name,
      required: required,
      type: %T.IntrospectionListTypeRef{
        ofType: %T.IntrospectionFieldReference{referenced_type: type}
      }
    }
  end

  defp extract_field(%Thrift.AST.Function{
         name: name,
         params: params,
         return_type: val
       })
       when val in @scalars or val in @id_like do
    %T.IntrospectionField{
      name: name,
      args: Enum.map(params, &extract_input_field/1),
      type: convert_scalar(val)
    }
  end

  defp extract_field(%Thrift.AST.Function{
         name: name,
         params: params,
         annotations: %{iface: type},
         return_type: %Thrift.AST.TypeRef{
           referenced_type: _t
         }
       }) do
    %T.IntrospectionField{
      args: Enum.map(params, &extract_input_field/1),
      name: name,
      type: %T.IntrospectionFieldReference{referenced_type: String.to_atom(type)}
    }
  end

  defp extract_field(%Thrift.AST.Function{
         name: name,
         params: params,
         return_type: %Thrift.AST.TypeRef{referenced_type: type}
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
       when val in @scalars or val in @id_like do
    %T.IntrospectionInputValue{name: name, type: convert_scalar(val)}
  end

  defp extract_input_field(%Thrift.AST.Field{
         name: name,
         type: %Thrift.AST.TypeRef{
           referenced_type: type
         }
       })
       when type in @id_like do
    %T.IntrospectionInputValue{name: name, type: convert_scalar(type)}
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
  defp convert_scalar(s) when s in @id_like, do: %T.IntrospectionScalarType{name: "ID"}
end
