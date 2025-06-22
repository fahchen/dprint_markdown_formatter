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

  @doc """
  Formats markdown text using default configuration.

  ## Examples

      iex> DprintMarkdownFormatter.format("# Hello    World")
      {:ok, "# Hello World\\n"}
      
      iex> DprintMarkdownFormatter.format("  * item1\\n*   item2")
      {:ok, "- item1\\n- item2\\n"}
  """
  @spec format(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def format(markdown_text) when is_binary(markdown_text) do
    DprintMarkdownFormatter.Native.format_markdown(markdown_text)
  rescue
    e -> {:error, "NIF error: #{inspect(e)}"}
  end
end
