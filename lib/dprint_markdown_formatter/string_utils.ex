defmodule DprintMarkdownFormatter.StringUtils do
  @moduledoc """
  String processing utilities for markdown formatting.

  This module contains pure functions for processing and normalizing markdown content,
  particularly for handling heredoc content and whitespace normalization.
  """

  @doc """
  Performs final cleanup of whitespace in formatted content.

  Removes whitespace-only lines that may have been left by intermediate processing
  steps, particularly in heredoc structures.

  ## Examples

      iex> DprintMarkdownFormatter.StringUtils.final_cleanup_whitespace("line1\\n   \\nline2")
      "line1\\n\\nline2"

      iex> DprintMarkdownFormatter.StringUtils.final_cleanup_whitespace("line1\\n\\t\\t\\nline2")
      "line1\\n\\nline2"
  """
  @spec final_cleanup_whitespace(String.t()) :: String.t()
  def final_cleanup_whitespace(content) when is_binary(content) do
    # Final pass to clean up any remaining whitespace-only lines in heredocs
    # This catches cases where Sourceror or intermediate processing leaves trailing spaces
    String.replace(content, ~r/^[ \t]+$/m, "")
  end
end
