defmodule LiveDevTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_dev_tools,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LiveDevTools.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_view, "~> 0.16"}
    ]
  end
end
