defmodule ThriftQlEx.ParserTest do
  use ExUnit.Case

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
    }

    service BarRegistry {
      StatusResponseEntity status()


      BigOlObject getBigOlObject(1: BigOlObjectType type, 2: string id, 3: double dbl, 4: i64 int)
      list<BigOlObject> getBigOlObjectByCustomerId(1: BigOlObjectType type, 2: string customerId, 3: bool foo)
    }
    """

    result =
      ~s({"data":{"__schema":{"types":[{"name":"Query","kind":"OBJECT","interfaces":[],"fields":[{"type":{"name":"BigOlObject","kind":"OBJECT"},"name":"getBigOlObject","isDeprecated":false,"description":null,"deprecationReason":null,"args":[{"type":{"name":"BigOlObjectType","kind":"ENUM"},"name":"type","description":null,"defaultValue":null},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"id","description":null,"defaultValue":null}]},{"type":{"ofType":{"name":"BigOlObject","kind":"OBJECT"},"kind":"LIST"},"name":"getBigOlObjectByCustomerId","isDeprecated":false,"description":null,"deprecationReason":null,"args":[{"type":{"name":"BigOlObjectType","kind":"ENUM"},"name":"type","description":null,"defaultValue":null},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"customer_id","description":null,"defaultValue":null}]},{"type":{"name":"StatusResponseEntity","kind":"OBJECT"},"name":"status","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"BigOlObject","kind":"OBJECT"},"name":"getBigOlObject","isDeprecated":false,"description":null,"deprecationReason":null,"args":[{"type":{"name":"BigOlObjectType","kind":"ENUM"},"name":"type","description":null,"defaultValue":null},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"id","description":null,"defaultValue":null}]},{"type":{"ofType":{"name":"BigOlObject","kind":"OBJECT"},"kind":"LIST"},"name":"getBigOlObjectByCustomerId","isDeprecated":false,"description":null,"deprecationReason":null,"args":[{"type":{"name":"BigOlObjectType","kind":"ENUM"},"name":"type","description":null,"defaultValue":null},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"customer_id","description":null,"defaultValue":null}]},{"type":{"name":"StatusResponseEntity","kind":"OBJECT"},"name":"status","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]}],"description":null},{"name":"BigOlObjectType","kind":"ENUM","enumValues":[{"name":"FATTY_TUNA","isDeprecated":false,"description":null,"deprecationReason":null},{"name":"LEAN_COD","isDeprecated":false,"description":null,"deprecationReason":null}],"description":null},{"name":"StatusType","kind":"ENUM","enumValues":[{"name":"healthy","isDeprecated":false,"description":null,"deprecationReason":null},{"name":"unhealthy","isDeprecated":false,"description":null,"deprecationReason":null}],"description":null},{"name":"BigOlObject","kind":"OBJECT","interfaces":[],"fields":[{"type":{"name":"String","kind":"SCALAR","description":null},"name":"id","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"name","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"Int","kind":"SCALAR","description":null},"name":"age","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"Float","kind":"SCALAR","description":null},"name":"foo","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"Boolean","kind":"SCALAR","description":null},"name":"bar","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"ofType":{"name":"Boolean","kind":"SCALAR","description":null},"kind":"LIST"},"name":"bool_list","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"ofType":{"name":"Int","kind":"SCALAR","description":null},"kind":"LIST"},"name":"i32_list","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"ofType":{"name":"Float","kind":"SCALAR","description":null},"kind":"LIST"},"name":"float_list","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"ofType":{"name":"String","kind":"SCALAR","description":null},"kind":"LIST"},"name":"bin_list","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"Nested","kind":"OBJECT"},"name":"nested","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]}],"description":null},{"name":"Nested","kind":"OBJECT","interfaces":[],"fields":[{"type":{"ofType":{"name":"Boolean","kind":"SCALAR","description":null},"kind":"LIST"},"name":"bool_list","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]}],"description":null},{"name":"StatusResponseEntity","kind":"OBJECT","interfaces":[],"fields":[{"type":{"name":"String","kind":"SCALAR","description":null},"name":"id","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"name","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"StatusType","kind":"ENUM"},"name":"status","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"name":"String","kind":"SCALAR","description":null},"name":"version","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]},{"type":{"ofType":{"name":"String","kind":"SCALAR","description":null},"kind":"LIST"},"name":"issues","isDeprecated":false,"description":null,"deprecationReason":null,"args":[]}],"description":null}],"subscriptionType":null,"queryType":{"name":"Query","kind":"OBJECT"},"mutationType":null,"directives":[]}}})

    {:ok, content} = ThriftQlEx.Parser.parse(service) |> Poison.encode()
    File.write!("schema.json", content)
    assert result == content
  end
end
