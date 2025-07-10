defmodule DprintMarkdownFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :dprint_markdown_formatter,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix]],
      package: package(),
      dprint_markdown_formatter: [
        line_width: 80,
        text_wrap: "always"
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
      {:rustler_precompiled, "~> 0.8"},
      {:rustler, "~> 0.36.0", optional: true},
      {:sourceror, "~> 1.0"},
      {:typed_structor, "~> 0.5.0"},
      {:mimic, "~> 1.7", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      description: "A fast, configurable markdown formatter for Elixir using Rust's dprint-plugin-markdown",
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "LICENSE"
      ],
      maintainers: ["Fah Chen"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/fahchen/dprint_markdown_formatter",
        "Documentation" => "https://hexdocs.pm/dprint_markdown_formatter"
      },
      keywords: [
        "markdown",
        "formatter",
        "dprint",
        "rust",
        "nif",
        "documentation",
        "moduledoc",
        "mix",
        "format"
      ]
    ]
  end

  defp aliases do
    [
      check: [
        "cmd --cd native/dprint_markdown_formatter cargo fmt",
        "cmd --cd native/dprint_markdown_formatter cargo clippy -- -D warnings",
        "format",
        "credo",
        "dialyzer"
      ]
    ]
  end
end
