defmodule DprintMarkdownFormatter.SigilTest do
  use ExUnit.Case, async: true
  import DprintMarkdownFormatter.Sigil

  doctest DprintMarkdownFormatter.Sigil

  describe "basic functionality" do
    test "returns formatted markdown string" do
      result = ~M"# Hello World"
      assert result == "# Hello World"
    end

    test "handles empty string" do
      result = ~M""
      assert result == ""
    end

    test "handles multiline content" do
      result = ~M"""
      # Title

      * Item 1
      * Item 2
      """

      assert result == "# Title\n\n- Item 1\n- Item 2"
    end
  end

  describe "formatting behavior" do
    test "formats extra spaces in headers" do
      result = ~M"# Hello    World"
      assert result == "# Hello World"
    end

    test "formats extra spaces in text" do
      result = ~M"This   has   extra   spaces."
      assert result == "This has extra spaces."
    end

    test "formats multiline content with extra spaces" do
      result = ~M"""
      # Hello    World

      This   has   extra   spaces.
      """

      assert result == "# Hello World\n\nThis has extra spaces."
    end
  end

  describe "modifier handling" do
    test "ignores all modifiers" do
      result = ~M"# Hello World"xyz
      assert result == "# Hello World"
    end

    test "ignores 'f' modifier and still formats" do
      result = ~M"# Hello    World"f
      assert result == "# Hello World"
    end

    test "works with multiple modifiers and still formats" do
      result = ~M"# Hello    World"abcf
      assert result == "# Hello World"
    end
  end
end
