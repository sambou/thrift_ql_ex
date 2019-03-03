defmodule PropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  require ExUnitProperties

  @string_like [:string, :binary]
  @int_like [:byte, :i8, :i16, :i32, :i64]
  @bool_like [:bool]
  @float_like [:double]
  @id_like [:id, :Id, :iD, :ID]
  @scalars @string_like ++ @int_like ++ @float_like ++ @bool_like
  @reserved ~w(BEGIN END __CLASS__ __DIR__ __FILE__ __FUNCTION__ __LINE__ __METHOD__ __NAMESPACE__
  abstract alias and args as assert begin break case catch class clone continue declare def default
  del delete do dynamic elif else elseif elsif end enddeclare endfor endforeach endif endswitch
  endwhile ensure except exec finally float for foreach from function global goto if id implements
  import in inline instanceof interface is lambda module native new next nil not or package pass
  public print private protected raise redo rescue retry register return self sizeof static super
  switch synchronized then this throw transient try undef unless unsigned until use var virtual volatile
  when while with xor yield)

  defp t_to_g(x) when x in @string_like, do: "String"
  defp t_to_g(x) when x in @int_like, do: "Int"
  defp t_to_g(x) when x in @bool_like, do: "Boolean"
  defp t_to_g(x) when x in @float_like, do: "Float"
  defp t_to_g("required"), do: "!"
  defp t_to_g(_), do: ""

  defp service_generator() do
    string =
      StreamData.string(?a..?z, min_length: 1)
      |> StreamData.filter(fn
        x when x in @reserved -> false
        _ -> true
      end)

    capitalized = string |> StreamData.map(&String.capitalize/1)
    required = StreamData.member_of(["required", ""])
    scalar = StreamData.member_of(@scalars)
    scalar_field = StreamData.tuple({string, scalar, required})

    ExUnitProperties.gen(
      all typedef_name <- capitalized,
          {typedef_field, typedef_type, typedef_required} <- scalar_field,
          {scalar_list_name, scalar_list_type, scalar_list_required} <- scalar_field,
          {scalar_field, scalar_type, scalar_required} <- scalar_field,
          struct_name <- capitalized,
          {nested_field, nested_required} <- {string, required},
          {object_list_name, object_list_required} <- {string, required},
          {enum_name, enum_value_1, enum_value_2} <- {capitalized, string, string},
          {union_name, union_name_1, union_name_2} <- {capitalized, string, string},
          service_name <- string,
          {query_name, arg_name, arg_type} <- {string, string, scalar} do
        thrift = """
        typedef #{typedef_type} #{typedef_name};
        typedef string Id;

        enum #{enum_name} {
          #{enum_value_1}
          #{enum_value_2}
        }

        union #{union_name} {
          1: #{struct_name} #{union_name_1};
          2: #{typedef_name} #{union_name_2};
        }

        struct #{struct_name} {
          1: #{scalar_required} #{scalar_type} #{scalar_field};
          2: #{nested_required} #{struct_name} #{nested_field};
          3: #{scalar_list_required} list<#{scalar_list_type}> #{scalar_list_name};
          4: #{object_list_required} list<#{struct_name}> #{object_list_name};
          5: #{typedef_required} #{typedef_name} #{typedef_field};
          6: Id id;
        }

        service #{service_name} {
          #{struct_name} #{query_name}(1: #{arg_type} #{arg_name});
        }
        """

        graphql = """
        schema {
        \tquery: Query
        }

        type Query {
        \t#{query_name}(#{arg_name}: #{t_to_g(arg_type)}): #{struct_name}
        }

        enum #{enum_name} {
        \t#{enum_value_1}
        \t#{enum_value_2}
        }

        type #{struct_name} {
        \t#{scalar_field}: #{t_to_g(scalar_type)}#{t_to_g(scalar_required)}
        \t#{nested_field}: #{struct_name}#{t_to_g(nested_required)}
        \t#{scalar_list_name}: [#{t_to_g(scalar_list_type)}]#{t_to_g(scalar_list_required)}
        \t#{object_list_name}: [#{struct_name}]#{t_to_g(object_list_required)}
        \t#{typedef_field}: #{typedef_name}#{t_to_g(typedef_required)}
        \tid: ID
        }

        scalar #{typedef_name}

        union #{union_name} = #{struct_name} | #{typedef_name}
        """

        {thrift, graphql}
      end
    )
  end

  property "parse and print should always produce valid schemas" do
    check all {service, schema} <- service_generator() do
      with {:ok, json} <- service |> ThriftQlEx.parse(),
           {:ok, created_schema} <- ThriftQlEx.print(json) do
        assert created_schema == schema
      else
        e -> throw(e)
      end
    end
  end
end
