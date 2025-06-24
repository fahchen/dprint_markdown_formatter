defmodule DprintMarkdownFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :dprint_markdown_formatter,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix]]
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
      {:rustler, "~> 0.36.0", optional: true},
      {:rustler_precompiled, "~> 0.8"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      check: [
        "cmd --cd native/dprint_markdown_formatter_nif cargo fmt",
        "cmd --cd native/dprint_markdown_formatter_nif cargo clippy",
        "format",
        "credo",
        "dialyzer"
      ]
    ]
  end
end
