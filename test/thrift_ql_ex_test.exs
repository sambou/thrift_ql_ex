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
      bool boo(1: string foo)
    }
    """

    expected_result = """
    schema {
    	query: Query
    }

    type Query {
    \tboo(foo: String): Boolean
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
    else
      e -> throw(e)
    end
  end

  test "Thrift sets get converted to GraphQL lists" do
    service = """
    struct Foo {
      1: set<string> ls1;
      2: set<i64> ls2;
      3: set<bool> ls3;
      4: set<double> ls4;
      5: set<Bar> ls5;
    }

    struct Bar {
      1: Baz baz;
      2: set<string> quuz;
    }

    struct Baz {
      1: Bar bar;
    }

    service MyService {
      Foo foo()
    }
    """

    expected_result = """
    schema {
    	query: Query
    }

    type Query {
    \tfoo: Foo
    }

    type Bar {
    \tbaz: Baz
    \tquuz: [String]
    }

    type Baz {
    \tbar: Bar
    }

    type Foo {
    \tls1: [String]
    \tls2: [Int]
    \tls3: [Boolean]
    \tls4: [Float]
    \tls5: [Bar]
    }
    """

    with {:ok, json} <- service |> ThriftQlEx.parse(),
         {:ok, sdl_schema} <- ThriftQlEx.print(json) do
      assert sdl_schema == expected_result
    else
      e -> throw(e)
    end
  end

  test "Thrift scalar typedefs get converted to GraphQL custom scalars" do
    service = """
    typedef string Date
    typedef string ID

    struct Foo {
      1: ID id;
      2: Date date;
      3: list<Date> dates;
    }

    service MyService {
      Foo foo()
    }
    """

    expected_result = """
    schema {
    	query: Query
    }

    type Query {
    \tfoo: Foo
    }

    type Foo {
    \tid: ID
    \tdate: Date
    \tdates: [Date]
    }

    scalar Date
    """

    with {:ok, json} <- service |> ThriftQlEx.parse(),
         {:ok, sdl_schema} <- ThriftQlEx.print(json) do
      assert sdl_schema == expected_result
    else
      e -> throw(e)
    end
  end

  test "Thrift unions get parsed into GraphQL unions" do
    service = """
    union Foo {
      1: Bar bar;
      2: Baz baz;
    }

    struct Bar {
      1: string bar;
    }

    struct Baz {
      1: string baz;
    }

    service MyService {
      Foo foo()
    }
    """

    expected_result = """
    schema {
    \tquery: Query
    }

    type Query {
    \tfoo: Foo
    }

    type Bar {
    \tbar: String
    }

    type Baz {
    \tbaz: String
    }

    union Foo = Bar | Baz
    """

    with {:ok, json} <- service |> ThriftQlEx.parse(),
         {:ok, sdl_schema} <- ThriftQlEx.print(json) do
      assert sdl_schema == expected_result
    else
      e -> throw(e)
    end
  end

  test "Thrift required fields get parsed into GraphQL NonNull fields" do
    service = """
    struct Bar {
      1: required string bar;
      2: required i64 foo;
      3: required list<Bar> baz;
      4: required Bar quuz;
    }

    service MyService {
      Bar foo(1: string quuz)
    }
    """

    expected_result = """
    schema {
    \tquery: Query
    }

    type Query {
    \tfoo(quuz: String): Bar
    }

    type Bar {
    \tbar: String!
    \tfoo: Int!
    \tbaz: [Bar]!
    \tquuz: Bar!
    }
    """

    with {:ok, json} <- service |> ThriftQlEx.parse(),
         {:ok, sdl_schema} <- ThriftQlEx.print(json) do
      assert sdl_schema == expected_result
    else
      e -> throw(e)
    end
  end

  test "Marking mutations with annotations" do
    service = """
    service MyService {
      string foo(1: string quuz)
      string bar(1: string quuz) (mutation)
    }
    """

    expected_result = """
    schema {
    \tquery: Query
    \tmutation: Mutation
    }

    type Mutation {
    \tbar(quuz: String): String
    }

    type Query {
    \tfoo(quuz: String): String
    }
    """

    with {:ok, json} <- service |> ThriftQlEx.parse(),
         {:ok, sdl_schema} <- ThriftQlEx.print(json) do
      assert sdl_schema == expected_result
    else
      e -> throw(e)
    end
  end
end
