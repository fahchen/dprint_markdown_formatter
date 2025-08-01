defmodule DprintMarkdownFormatter.PatchBuilder do
  @moduledoc """
  Utilities for building replacement strings and patches for formatted content.

  Handles the conversion of formatted markdown content into appropriate string
  replacements, supporting both simple strings and heredoc formats.
  """

  @doc """
  Builds a replacement string for formatted content based on the original
  delimiter.

  Automatically handles conversion between simple strings and heredocs when
  content becomes multi-line.

  ## Examples

      iex> DprintMarkdownFormatter.PatchBuilder.build_replacement_string("Hello", "\\\"")
      "\\"Hello\\""

      iex> DprintMarkdownFormatter.PatchBuilder.build_replacement_string("Hello\\nWorld", "\\\"")
      "\\\"\\\"\\\"\\nHello\\nWorld\\n\\\"\\\"\\\""

      iex> DprintMarkdownFormatter.PatchBuilder.build_replacement_string("Hello\\nWorld", "\\\"\\\"\\\"")
      "\\\"\\\"\\\"\\nHello\\nWorld\\n\\\"\\\"\\\""
  """
  @spec build_replacement_string(String.t(), String.t()) :: String.t()
  def build_replacement_string(formatted, delimiter) do
    if delimiter == "\"" do
      build_simple_string_replacement(formatted)
    else
      build_heredoc_replacement(formatted)
    end
  end

  @doc """
  Builds a replacement string for simple string content.

  If the content contains newlines, it will be converted to heredoc format.
  Otherwise, it remains as a simple quoted string.

  ## Examples

      iex> DprintMarkdownFormatter.PatchBuilder.build_simple_string_replacement("Hello")
      "\\"Hello\\""

      iex> DprintMarkdownFormatter.PatchBuilder.build_simple_string_replacement("Hello\\nWorld")
      "\\\"\\\"\\\"\\nHello\\nWorld\\n\\\"\\\"\\\""
  """
  @spec build_simple_string_replacement(String.t()) :: String.t()
  def build_simple_string_replacement(formatted) do
    if String.contains?(formatted, "\n") do
      # Convert to heredoc if content becomes multi-line
      "\"\"\"\n#{formatted}\n\"\"\""
    else
      # Keep as simple string
      "\"#{formatted}\""
    end
  end

  @doc """
  Builds a replacement string for heredoc content.

  Always preserves the heredoc format regardless of content.

  ## Examples

      iex> DprintMarkdownFormatter.PatchBuilder.build_heredoc_replacement("Hello")
      "\\\"\\\"\\\"\\nHello\\n\\\"\\\"\\\""

      iex> DprintMarkdownFormatter.PatchBuilder.build_heredoc_replacement("Hello\\nWorld")
      "\\\"\\\"\\\"\\nHello\\nWorld\\n\\\"\\\"\\\""
  """
  @spec build_heredoc_replacement(String.t()) :: String.t()
  def build_heredoc_replacement(formatted) do
    # Heredoc format - preserve as heredoc
    "\"\"\"\n#{formatted}\n\"\"\""
  end

  @doc """
  Builds a replacement string for sigil content, preserving the original sigil
  type and delimiter.

  Handles all supported sigil delimiters and maintains proper formatting for both
  simple and heredoc-style sigils.

  ## Examples

      iex> DprintMarkdownFormatter.PatchBuilder.build_replacement_sigil_string("Hello", "~S", "\\"")
      "~S\\"Hello\\""

      iex> DprintMarkdownFormatter.PatchBuilder.build_replacement_sigil_string("Hello\\nWorld", "~S", "\\"\\"\\\"")
      "~S\\"\\"\\\"\\nHello\\nWorld\\n\\"\\"\\""

      iex> DprintMarkdownFormatter.PatchBuilder.build_replacement_sigil_string("Hello", "~s", "/")
      "~s/Hello/"
  """
  @spec build_replacement_sigil_string(String.t(), String.t(), String.t()) :: String.t()
  def build_replacement_sigil_string(formatted, sigil_prefix, delimiter) do
    case delimiter do
      "\"\"\"" ->
        # Heredoc sigil - format exactly like regular heredocs
        # Match expected format: newline after closing delimiter
        "#{sigil_prefix}\"\"\"\n#{formatted}\n\"\"\"\n"

      "'''" ->
        # Triple single quote heredoc - same as triple double quotes
        # Match expected format: newline after closing delimiter
        "#{sigil_prefix}'''\n#{formatted}\n'''\n"

      single_delimiter when single_delimiter in ["\"", "'", "/", "|", "(", "[", "{", "<"] ->
        # Single character delimiters - preserve original delimiter structure
        closing_delimiter = get_closing_delimiter(single_delimiter)

        # For simple delimiters, match the expected format precisely
        # Single-line sigils should not have trailing newline
        # Multi-line sigils should have newline after closing delimiter
        has_newlines = String.contains?(formatted, "\n")

        if has_newlines do
          # Multi-line content needs newline after closing delimiter
          "#{sigil_prefix}#{single_delimiter}\n#{formatted}\n#{closing_delimiter}\n"
        else
          # Single-line content - no trailing newline
          "#{sigil_prefix}#{single_delimiter}#{formatted}#{closing_delimiter}"
        end

      _ ->
        # Fallback to heredoc for unknown delimiters
        "#{sigil_prefix}\"\"\"\n#{formatted}\n\"\"\"\n"
    end
  end

  # Private helper to get the closing delimiter for bracket-style delimiters
  defp get_closing_delimiter(opening) do
    case opening do
      "(" -> ")"
      "[" -> "]"
      "{" -> "}"
      "<" -> ">"
      # For quotes, slashes, pipes - closing is same as opening
      other -> other
    end
  end
end
