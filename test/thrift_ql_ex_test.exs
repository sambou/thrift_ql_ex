defmodule ThriftQlExTest do
  use ExUnit.Case
  doctest ThriftQlEx

  test "converts Thrift to GraphQL JSON" do
    service = """
    enum StatusType {
      healthy,
      unhealthy
    }

    struct StatusResponseEntity {
      1: string id;
      2: string name;
      3: StatusType status;
      4: string version;
      5: optional list<string> issues;
    }

    struct BigOlObject {
      1: string id;
      2: string name;
      3: i64 age;
      4: double foo;
      5: bool bar;
      6: optional list<bool> boolList;
      7: optional list<i32> i32List;
      8: list<double> floatList;
      9: list<binary> binList;
      10: Nested nested;
      11: list<Nested> nestedList;
    }

    struct Nested {
      6: optional list<bool> boolList;
    }

    enum BigOlObjectType {
      FATTY_TUNA,
      LEAN_COD
    }

    service FooRegistry {
      StatusResponseEntity status()

      BigOlObject getBigOlObject(1: BigOlObjectType type, 2: string id)
      list<BigOlObject> getBigOlObjectByCustomerId(1: BigOlObjectType type, 2: string customerId)
      string foo()
    }
    """

    expected_result = """
    schema {
    	query: Query
    }

    type Query {
    \tfoo: String
    \tgetBigOlObject(type: BigOlObjectType, id: String): BigOlObject
    \tgetBigOlObjectByCustomerId(type: BigOlObjectType, customer_id: String): [BigOlObject]
    \tstatus: StatusResponseEntity
    }

    enum BigOlObjectType {
    	FATTY_TUNA
    	LEAN_COD
    }

    enum StatusType {
    	healthy
    	unhealthy
    }

    type BigOlObject {
    	id: String
    	name: String
    	age: Int
    	foo: Float
    	bar: Boolean
    	bool_list: [Boolean]
    	i32_list: [Int]
    	float_list: [Float]
    	bin_list: [String]
    	nested: Nested
    	nested_list: [Nested]
    }

    type Nested {
    	bool_list: [Boolean]
    }

    type StatusResponseEntity {
    	id: String
    	name: String
    	status: StatusType
    	version: String
    	issues: [String]
    }
    """

    with {:ok, json} <- service |> ThriftQlEx.parse(),
         {:ok, sdl_schema} <- ThriftQlEx.print(json) do
      assert sdl_schema == expected_result
    end
  end
end
