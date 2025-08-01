defmodule DprintMarkdownFormatter.MixProject do
  use Mix.Project

  @version "0.4.0"
  @source_url "https://github.com/fahchen/dprint_markdown_formatter"

  def project do
    [
      app: :dprint_markdown_formatter,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix]],
      package: package(),
      docs: docs(),
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
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description:
        "A fast, configurable markdown formatter for Elixir using Rust's dprint-plugin-markdown",
      files: [
        "lib",
        "native",
        "checksum-*.exs",
        "mix.exs",
        "README.md",
        "LICENSE",
        "llms.txt"
      ],
      maintainers: ["Phil Chen"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
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

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "llms.txt"],
      groups_for_modules: [
        Core: [
          DprintMarkdownFormatter,
          DprintMarkdownFormatter.Config,
          DprintMarkdownFormatter.Error
        ],
        Sigil: [
          DprintMarkdownFormatter.Sigil
        ],
        Internal: [
          DprintMarkdownFormatter.Native,
          DprintMarkdownFormatter.Validator
        ]
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
