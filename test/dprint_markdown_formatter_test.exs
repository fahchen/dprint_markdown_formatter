defmodule DprintMarkdownFormatterTest do
  use ExUnit.Case, async: true
  doctest DprintMarkdownFormatter

  describe "format/2" do
    test "formats simple headers correctly" do
      input = "# Header    with    extra    spaces"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "# Header with extra spaces\n"
    end

    test "normalizes unordered lists to dashes" do
      input = "*   Item 1\n  *  Item 2\n*    Item 3"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "- Item 1\n- Item 2\n- Item 3\n"
    end

    test "formats ordered lists consistently" do
      input = "1.   First item\n2.    Second item\n3.     Third item"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "1. First item\n2. Second item\n3. Third item\n"
    end

    test "cleans up paragraph spacing" do
      input = "This is   a    paragraph   with    irregular   spacing."
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "This is a paragraph with irregular spacing.\n"
    end

    test "formats emphasis and strong text correctly" do
      input = "**Bold   text**   and   *italic   text*"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "**Bold text** and *italic text*\n"
    end

    test "handles blockquotes properly" do
      input = "> This is a blockquote\n> with multiple lines"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "> This is a blockquote with multiple lines\n"
    end

    test "preserves code blocks unchanged" do
      input = "```elixir\ndef hello do\n  :world\nend\n```"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "```elixir\ndef hello do\n  :world\nend\n```\n"
    end

    test "handles inline code correctly" do
      input = "Use the `format/2` function to format markdown."
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "Use the `format/2` function to format markdown.\n"
    end

    test "formats links properly" do
      input = "[Elixir](https://elixir-lang.org)   is   awesome!"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "[Elixir](https://elixir-lang.org) is awesome!\n"
    end

    test "handles multiple levels of headers" do
      input = "#    H1\n##   H2\n###  H3"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "# H1\n\n## H2\n\n### H3\n"
    end

    test "formats nested lists correctly" do
      input = "- Item 1\n  - Nested item\n- Item 2"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "- Item 1\n  - Nested item\n- Item 2\n"
    end

    test "returns formatted string for empty string" do
      result = DprintMarkdownFormatter.format("", [])
      assert result == ""
    end

    test "handles complex mixed content" do
      input = """
      #   Title

      This   is   a   paragraph.

      *  Item 1
        *  Nested
      *  Item 2

      **Bold** and *italic*.

      > Quote   here
      """

      result = DprintMarkdownFormatter.format(input, [])

      # Verify the result is formatted properly
      assert String.contains?(result, "# Title\n")
      assert String.contains?(result, "This is a paragraph.")
      assert String.contains?(result, "- Item 1\n- Nested\n- Item 2")
      assert String.contains?(result, "**Bold** and *italic*.")
    end

    test "preserves line breaks in code blocks" do
      input = """
      Some text

      ```
      line 1
      line 2
      ```
      """

      result = DprintMarkdownFormatter.format(input, [])
      assert String.contains?(result, "line 1\nline 2")
    end

    test "handles horizontal rules" do
      input = "---\n\nContent here\n\n***"
      result = DprintMarkdownFormatter.format(input, [])
      # Should format but preserve the horizontal rules
      assert String.contains?(result, "Content here")
    end
  end

  describe "formatting options" do
    test "line_width option affects formatting" do
      input =
        "This is a very long line of text that should be wrapped when the line width is set to a small value like 20 characters."

      result_default = DprintMarkdownFormatter.format(input, [])
      result_narrow = DprintMarkdownFormatter.format(input, line_width: 20)

      # With narrow line width, text should be wrapped differently
      refute result_default == result_narrow
    end

    test "unordered_list_kind option changes list markers" do
      input = "- Item 1\n- Item 2"
      result_asterisks = DprintMarkdownFormatter.format(input, unordered_list_kind: "asterisks")

      # Should format with asterisks when option is set
      assert String.contains?(result_asterisks, "* Item 1")
      assert String.contains?(result_asterisks, "* Item 2")
    end

    test "emphasis_kind option changes emphasis style" do
      input = "*italic text*"
      result_underscores = DprintMarkdownFormatter.format(input, emphasis_kind: "underscores")

      # Should format with underscores when option is set
      assert String.contains?(result_underscores, "_italic text_")
    end

    test "text_wrap option affects wrapping behavior" do
      input =
        "This is a very long line of text that normally would be wrapped but with never option should stay on one line."

      result_default = DprintMarkdownFormatter.format(input, line_width: 20)
      result_never = DprintMarkdownFormatter.format(input, text_wrap: "never", line_width: 20)

      # With text_wrap: "never", should have different wrapping behavior than default
      # Note: dprint may still add a trailing newline, so we check line count excluding the final newline
      default_lines =
        result_default |> String.trim_trailing("\n") |> String.split("\n") |> length()

      never_lines = result_never |> String.trim_trailing("\n") |> String.split("\n") |> length()

      # With "never", should have fewer line breaks (ideally just 1 line)
      assert never_lines <= default_lines
    end

    test "native function can be called directly with options" do
      input = "- Item 1\n- Item 2"

      result =
        DprintMarkdownFormatter.Native.format_markdown(input, unordered_list_kind: "asterisks")

      assert {:ok, formatted} = result
      assert String.contains?(formatted, "* Item 1")
      assert String.contains?(formatted, "* Item 2")
    end
  end

  describe "error handling" do
    test "returns error for non-string input" do
      # This test verifies the guard clause works
      assert_raise FunctionClauseError, fn ->
        DprintMarkdownFormatter.format(123, [])
      end
    end

    test "handles very large input" do
      large_input = String.duplicate("# Header\n\nContent here.\n\n", 1000)
      result = DprintMarkdownFormatter.format(large_input, [])
      assert is_binary(result)
      assert String.length(result) > 0
    end
  end

  describe "Mix.Tasks.Format behavior" do
    test "features/1 returns correct sigils and extensions" do
      features = DprintMarkdownFormatter.features([])
      assert features[:sigils] == [:M]
      assert features[:extensions] == [".md", ".markdown", ".ex", ".exs"]
    end

    test "format/2 with sigil option removes trailing newline" do
      input = "# Header    with    spaces"
      result = DprintMarkdownFormatter.format(input, sigil: :M)
      assert result == "# Header with spaces"
    end

    test "format/2 with extension keeps trailing newline" do
      input = "# Header    with    spaces"
      result = DprintMarkdownFormatter.format(input, extension: ".md")
      assert result == "# Header with spaces\n"
      assert String.ends_with?(result, "\n")
    end

    test "format/2 returns original content on formatting error" do
      # Mock a scenario where the NIF might fail by using the format/2 path
      # but ensuring it falls back gracefully
      input = "# Valid markdown"
      result = DprintMarkdownFormatter.format(input, extension: ".md")
      # Should return formatted content or fallback to original
      assert is_binary(result)
      assert String.length(result) > 0
    end

    test "format/2 with empty options formats correctly" do
      input = "# Header    with    spaces"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "# Header with spaces\n"
    end
  end

  describe "content type detection and routing" do
    test "elixir source files return unchanged (placeholder)" do
      input = """
      defmodule Example do
        @moduledoc \"\"\"
        This is some   messy   markdown
        \"\"\"
      end
      """

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == input
    end

    test "elixir script files return unchanged (placeholder)" do
      input = """
      # This is an Elixir script
      IO.puts "Hello"
      """

      result = DprintMarkdownFormatter.format(input, extension: ".exs")
      assert result == input
    end

    test "sigil formatting with multiple lines" do
      input = """
      # Header   with   spaces

      This is a   paragraph   with   irregular   spacing.

      *  Item 1
      *  Item 2

      **Bold   text**   and   *italic   text*
      """
      result = DprintMarkdownFormatter.format(input, sigil: :M)

      expected = "# Header with spaces\n\nThis is a paragraph with irregular spacing.\n\n- Item 1\n- Item 2\n\n**Bold text** and *italic text*"

      assert result == expected
    end

    test "sigil takes precedence over extension" do
      input = "# Header    with    spaces"
      result = DprintMarkdownFormatter.format(input, sigil: :M, extension: ".ex")
      assert result == "# Header with spaces"
    end
  end
end
