defmodule ThriftQlEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :thrift_ql_ex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:poison, "~> 3.1"}
    ]
  end
end
