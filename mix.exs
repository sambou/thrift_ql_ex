defmodule ThriftQlEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :thrift_ql_ex,
      version: "0.3.0",
      elixir: "~> 1.7",
      start_permanent: false,
      deps: deps(),
      description: "Converts Thrift IDL into GraphQL SDL.",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: [
        licenses: ["MIT"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:thrift, github: "pinterest/elixir-thrift", submodules: true},
      {:excoveralls, "~> 0.10", only: :test, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:poison, "~> 4.0"},
      {:stream_data, "~> 0.1", only: :test},
      {:credo, "~> 1.5.3", only: [:dev, :test], runtime: false}
    ]
  end
end
