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
end
