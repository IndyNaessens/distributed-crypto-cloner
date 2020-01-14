defmodule Reporter.MixProject do
  use Mix.Project

  def project do
    [
      app: :reporter,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Assignment.Reporter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:scribe, "~> 0.10.0"},
      {:libcluster, "~> 3.2"}
    ]
  end
end
