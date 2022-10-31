defmodule EthculePoirot.MixProject do
  use Mix.Project

  def project do
    [
      app: :ethcule_poirot,
      version: "0.5.0",
      elixir: "~> 1.14.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EthculePoirot.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:neuron, "~> 5.0.0"},
      {
        :bolt_sips,
        git: "https://github.com/zediogoviana/bolt_sips", branch: "master"
      },
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:decimal, "~> 2.0"}
    ]
  end
end
