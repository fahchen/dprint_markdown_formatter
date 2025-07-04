defmodule DprintMarkdownFormatter do
  @moduledoc """
  A fast markdown formatter using dprint-plugin-markdown via Rustler NIF.

  This module provides an interface to format markdown text using the 
  dprint-plugin-markdown formatter implemented in Rust for performance.

  ## Configuration

  Options for dprint can be configured in `mix.exs`:

      def project do
        [
          # ... other config
          dprint_markdown_formatter: [
            line_width: 100,
            text_wrap: "never",
            emphasis_kind: "underscores"
          ]
        ]
      end

  ### Available Options

  - `:line_width` - Maximum line width (default: 80)
  - `:text_wrap` - Text wrapping behavior: `:always`, `:never`, `:maintain` (default: `:always`)
  - `:emphasis_kind` - Emphasis style: `:asterisks`, `:underscores` (default: `:asterisks`)
  - `:strong_kind` - Strong text style: `:asterisks`, `:underscores` (default: `:asterisks`)
  - `:new_line_kind` - Line ending type: `:auto`, `:lf`, `:crlf` (default: `:auto`)
  - `:unordered_list_kind` - Unordered list style: `:dashes`, `:asterisks` (default: `:dashes`)

  ## Sigil Support

  For convenient markdown handling, you can use the ~M sigil:

      import DprintMarkdownFormatter.Sigil

      # Raw markdown
      markdown = ~M\"\"\"
      # Hello World
      
      Some content here.
      \"\"\"

  """

  @behaviour Mix.Tasks.Format

  @doc """
  Returns the features supported by this formatter plugin.

  This plugin supports:
  - The ~M sigil for markdown content
  - Files with .md and .markdown extensions
  """
  @impl Mix.Tasks.Format
  @spec features(keyword()) :: [sigils: [atom()], extensions: [String.t()]]
  def features(_opts) do
    [sigils: [:M], extensions: [".md", ".markdown"]]
  end

  @doc """
  Formats markdown text using dprint-plugin-markdown.

  Returns the formatted string directly, or returns original content if formatting fails.

  ## Examples

      iex> DprintMarkdownFormatter.format("# Hello    World", [])
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("# Hello    World", extension: ".md")
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("# Hello    World", sigil: :M)
      "# Hello World"

      iex> DprintMarkdownFormatter.format("# Hello    World", line_width: 60)
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("* Item 1\\n* Item 2", unordered_list_kind: "asterisks")
      "* Item 1\\n* Item 2\\n"
  """
  @impl Mix.Tasks.Format
  @spec format(String.t(), keyword()) :: String.t()
  def format(contents, opts) when is_binary(contents) and is_list(opts) do
    # Get dprint options from Mix.exs configuration and merge with runtime options
    config_opts = get_config_from_mix()

    {runtime_dprint_opts, _format_opts} =
      Keyword.split(opts, [
        :line_width,
        :text_wrap,
        :emphasis_kind,
        :strong_kind,
        :new_line_kind,
        :unordered_list_kind
      ])

    dprint_opts = Keyword.merge(config_opts, runtime_dprint_opts)

    case DprintMarkdownFormatter.Native.format_markdown(contents, dprint_opts) do
      {:ok, formatted} ->
        # Handle different return types based on options
        if Keyword.has_key?(opts, :sigil) do
          # For sigils, remove trailing newline that dprint adds for consistency with sigil usage
          String.trim_trailing(formatted, "\n")
        else
          formatted
        end

      {:error, _reason} ->
        # If formatting fails, return original content unchanged
        contents
    end
  rescue
    _error ->
      # If formatting fails, return original content unchanged
      contents
  end

  defp get_config_from_mix do
    case Mix.Project.config()[:dprint_markdown_formatter] do
      nil -> []
      config when is_list(config) -> config
      _invalid -> []
    end
  end

  defp get_doc_attributes(config) do
    default_attributes = [
      moduledoc: true,
      doc: true,
      typedoc: true,
      shortdoc: true,
      deprecated: true
    ]

    case Keyword.get(config, :doc_attributes) do
      nil -> default_attributes
      attrs when is_list(attrs) -> Keyword.merge(default_attributes, attrs)
      _invalid -> default_attributes
    end
  end
end
