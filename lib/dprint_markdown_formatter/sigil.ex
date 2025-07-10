defmodule DprintMarkdownFormatter.Sigil do
  @moduledoc """
  Provides the ~M sigil for embedding markdown content in Elixir code.

  The ~M sigil creates markdown strings that can be used directly in your
  application without any additional processing.

  ## Usage

      import DprintMarkdownFormatter.Sigil

      # Simple markdown
      title = ~M"# Welcome to My App"

      # Multi-line markdown with code blocks
      docs = ~M\"\"\"
      # API Documentation

      ## Authentication

      ```elixir
      defmodule MyApp.Auth do
        def authenticate(token) do
          # Implementation here
        end
      end
      ```

      ## Usage

      Call the authenticate function with your token.
      \"\"\"

  ## Modifiers

  The ~M sigil ignores all modifiers and always returns the raw markdown string.
  """

  @doc """
  Creates a markdown string from the given content.

  The ~M sigil creates a raw markdown string that can be formatted by `mix format`
  when the DprintMarkdownFormatter plugin is configured.

  ## Examples

      iex> import DprintMarkdownFormatter.Sigil
      iex> ~M"# Hello World"
      "# Hello World"

      iex> import DprintMarkdownFormatter.Sigil
      iex> ~M"**Bold** and *italic* text"
      "**Bold** and *italic* text"

      iex> import DprintMarkdownFormatter.Sigil
      iex> ~M\"\"\"
      ...> # Title
      ...> 
      ...> Content here.
      ...> \"\"\"
      "# Title\\n\\nContent here.\\n"
  """
  @spec sigil_M(binary(), list()) :: binary()
  def sigil_M(markdown, _modifiers) when is_binary(markdown) do
    markdown
  end
end
