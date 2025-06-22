defmodule DprintMarkdownFormatter do
  @moduledoc """
  A fast markdown formatter using dprint-plugin-markdown via Rustler NIF.

  This module provides an interface to format markdown text using the 
  dprint-plugin-markdown formatter implemented in Rust for performance.

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
  """
  @spec format(String.t(), keyword()) :: String.t()
  def format(contents, opts) when is_binary(contents) and is_list(opts) do
    case DprintMarkdownFormatter.Native.format_markdown(contents) do
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
    _e ->
      # If formatting fails, return original content unchanged
      contents
  end
end
