defmodule DprintMarkdownFormatter.Sigil do
  @moduledoc """
  Provides the ~M sigil for embedding formatted markdown content in Elixir code.

  The ~M sigil creates formatted markdown strings using the dprint-plugin-markdown
  formatter. The content is automatically formatted according to the current
  configuration, ensuring consistent markdown output.

  ## Key Features

  - **Automatic formatting**: Extra spaces, inconsistent list styles, and other formatting issues are corrected
  - **Configuration-aware**: Uses the same configuration as the main formatter
  - **Compile-time processing**: Formatting happens when the sigil is evaluated
  - **Error handling**: Falls back gracefully if formatting fails

  ## Usage

      import DprintMarkdownFormatter.Sigil

      # Extra spaces are formatted
      title = ~M"# Welcome    to    My    App"
      # Returns: "# Welcome to My App"

      # Lists use configured style
      items = ~M"* Item 1\\n* Item 2"
      # Returns: "- Item 1\\n- Item 2"

      # Multi-line content is formatted
      docs = ~M\"\"\"
      # API    Documentation

      Call   the   authenticate   function.
      \"\"\"

  ## Configuration

  The sigil uses the same configuration as the main formatter. See
  `DprintMarkdownFormatter` for available options like:

  - `:line_width` - Maximum line width
  - `:unordered_list_kind` - List bullet style (`:dashes` or `:asterisks`)
  - `:emphasis_kind` - Emphasis style (`:asterisks` or `:underscores`)

  ## Modifiers

  The ~M sigil ignores all modifiers and always returns the formatted markdown string.
  """

  @doc """
  Creates a formatted markdown string from the given content.

  The ~M sigil processes markdown content using the dprint-plugin-markdown
  formatter with the current configuration. The content is normalized and
  formatted according to the configured style rules.

  ## Parameters

  - `markdown` - The markdown content as a binary string
  - `modifiers` - List of modifiers (ignored by this sigil)

  ## Returns

  A formatted markdown string with consistent spacing, list styles, and other
  formatting applied according to the current configuration.

  ## Examples

      iex> import DprintMarkdownFormatter.Sigil
      iex> ~M"# Hello    World"
      "# Hello World"

      iex> import DprintMarkdownFormatter.Sigil
      iex> ~M"**Bold**  and  *italic*  text"
      "**Bold** and *italic* text"

      iex> import DprintMarkdownFormatter.Sigil
      iex> ~M\"\"\"
      ...> # Title
      ...> 
      ...> Content here.
      ...> \"\"\"
      "# Title\\n\\nContent here."

  ## Error Handling

  The underlying `DprintMarkdownFormatter.format/2` function handles errors
  gracefully and returns the original content if formatting fails, ensuring
  your code continues to work even if there are formatting issues.
  """
  @spec sigil_M(binary(), list()) :: binary()
  def sigil_M(markdown, _modifiers) when is_binary(markdown) do
    DprintMarkdownFormatter.format(markdown, sigil: :M)
  end
end
