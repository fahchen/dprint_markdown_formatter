defmodule DprintMarkdownFormatter.StringUtilsTest do
  use ExUnit.Case, async: true
  doctest DprintMarkdownFormatter.StringUtils

  alias DprintMarkdownFormatter.StringUtils

  describe "final_cleanup_whitespace/1" do
    test "removes whitespace-only lines with spaces" do
      input = "line1\n   \nline2"
      expected = "line1\n\nline2"
      assert StringUtils.final_cleanup_whitespace(input) == expected
    end

    test "removes whitespace-only lines with tabs" do
      input = "line1\n\t\t\nline2"
      expected = "line1\n\nline2"
      assert StringUtils.final_cleanup_whitespace(input) == expected
    end

    test "removes whitespace-only lines with mixed spaces and tabs" do
      input = "line1\n \t \nline2"
      expected = "line1\n\nline2"
      assert StringUtils.final_cleanup_whitespace(input) == expected
    end

    test "preserves empty lines" do
      input = "line1\n\nline2"
      expected = "line1\n\nline2"
      assert StringUtils.final_cleanup_whitespace(input) == expected
    end

    test "preserves content lines with leading whitespace" do
      input = "line1\n  content\nline2"
      expected = "line1\n  content\nline2"
      assert StringUtils.final_cleanup_whitespace(input) == expected
    end

    test "handles empty string" do
      assert StringUtils.final_cleanup_whitespace("") == ""
    end

    test "handles single line" do
      assert StringUtils.final_cleanup_whitespace("single line") == "single line"
    end
  end

  describe "edge cases and integration" do
    test "all functions handle empty strings gracefully" do
      assert StringUtils.final_cleanup_whitespace("") == ""
    end

    test "handles real markdown content structure" do
      markdown = """
        # Title

        This is a paragraph with some content.

        ## Subsection

        - Item 1
        - Item 2
          - Nested item

        Some **bold** and *italic* text.
      """

      # Should preserve the structure while cleaning up whitespace-only lines
      result = StringUtils.final_cleanup_whitespace(markdown)

      # The content should remain the same since there are no whitespace-only lines
      assert result == markdown
    end
  end
end
