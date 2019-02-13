defmodule ThriftQlEx.Types do
  @moduledoc false

  defmodule IntrospectionQuery do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :__schema
    defstruct __schema: nil
  end

  defmodule IntrospectionSchema do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :queryType
    defstruct queryType: nil, mutationType: nil, subscriptionType: nil, types: [], directives: []
  end

  defmodule IntrospectionScalarType do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :name
    defstruct kind: "SCALAR", name: nil, description: nil
  end

  defmodule IntrospectionObjectType do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :name
    defstruct kind: "OBJECT", name: nil, description: nil, fields: [], interfaces: []
  end

  defmodule IntrospectionInterfaceType do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :name
    defstruct kind: "INTERFACE", name: nil, description: nil, fields: [], possibleTypes: []
  end

  defmodule IntrospectionUnionType do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :name
    defstruct kind: "UNION", name: nil, description: nil, possibleTypes: []
  end

  defmodule IntrospectionEnumType do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :name
    defstruct kind: "ENUM", name: nil, description: nil, enumValues: []
  end

  defmodule IntrospectionInputObjectType do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :name
    defstruct kind: "INPUT_OBJECT", ofType: nil, name: nil, description: nil, inputFields: []
  end

  defmodule IntrospectionNamedTypeRef do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys :kind
    defstruct kind: nil, name: nil
  end

  defmodule IntrospectionListTypeRef do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys [:ofType]
    defstruct kind: "LIST", ofType: nil
  end

  defmodule IntrospectionFieldReference do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys [:referenced_type]
    defstruct name: nil,
              args: [],
              description: nil,
              referenced_type: nil,
              isDeprecated: false,
              deprecationReason: nil
  end

  defmodule IntrospectionField do
    @moduledoc false

    @derive [Poison.Encoder]
    @enforce_keys [:name, :type]
    defstruct name: nil,
              args: [],
              description: nil,
              type: nil,
              isDeprecated: false,
              deprecationReason: nil
  end

  defmodule IntrospectionInputValue do
    @moduledoc false

    @derive [Poison.Encoder]
    defstruct name: nil,
              description: nil,
              type: nil,
              defaultValue: nil
  end

  defmodule IntrospectionInputValueReference do
    @moduledoc false

    @derive [Poison.Encoder]
    defstruct name: nil,
              description: nil,
              referenced_type: nil,
              defaultValue: nil
  end

  defmodule IntrospectionEnumValue do
    @moduledoc false

    @derive [Poison.Encoder]
    defstruct name: nil,
              description: nil,
              isDeprecated: false,
              deprecationReason: nil
  end

  @type introspectionType ::
          %IntrospectionScalarType{}
          | %IntrospectionObjectType{}
          | %IntrospectionInterfaceType{}
          | %IntrospectionEnumType{}
          | %IntrospectionUnionType{}
          | %IntrospectionInputObjectType{}

  @type introspectionOutputType ::
          %IntrospectionScalarType{}
          | %IntrospectionObjectType{}
          | %IntrospectionInterfaceType{}
          | %IntrospectionEnumType{}
          | %IntrospectionUnionType{}

  @type introspectionInputType ::
          %IntrospectionScalarType{}
          | %IntrospectionInputObjectType{}
          | %IntrospectionEnumType{}
end
