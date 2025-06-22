defmodule DprintMarkdownFormatter.SigilTest do
  use ExUnit.Case, async: true
  import DprintMarkdownFormatter.Sigil

  doctest DprintMarkdownFormatter.Sigil

  describe "~M sigil" do
    test "returns raw markdown string" do
      result = ~M"# Hello World"
      assert result == "# Hello World"
    end

    test "preserves formatting and whitespace" do
      result = ~M"""
      # Hello    World

      This   has   extra   spaces.
      """

      assert result == "# Hello    World\n\nThis   has   extra   spaces.\n"
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

      assert String.contains?(result, "# Title")
      assert String.contains?(result, "* Item 1")
      assert String.contains?(result, "* Item 2")
    end

    test "ignores all modifiers" do
      result = ~M"# Hello World"xyz
      assert result == "# Hello World"
    end

    test "ignores 'f' modifier" do
      result = ~M"# Hello    World"f
      assert result == "# Hello    World"
    end

    test "works with multiple modifiers" do
      result = ~M"# Hello World"abcf
      assert result == "# Hello World"
    end
  end

  describe "practical usage examples" do
    test "documentation example" do
      markdown = ~M"""
      # API Documentation

      ## User Management

      * Create user
      * Update user  
      * Delete user
      """

      # Verify the raw markdown is preserved
      assert String.contains?(markdown, "# API Documentation")
      assert String.contains?(markdown, "* Create user")
      assert String.contains?(markdown, "* Update user")
      assert String.contains?(markdown, "* Delete user")
    end

    test "email template example" do
      template = ~M"""
      # Welcome   to   Our   Service!

      **Thank you** for signing up.

      ## Next Steps:

      1.   Verify your email
      2.   Complete your profile
      3.   Start using the service
      """

      assert String.contains?(template, "# Welcome   to   Our   Service!")
      assert String.contains?(template, "1.   Verify your email")
      assert String.contains?(template, "2.   Complete your profile")
      assert String.contains?(template, "3.   Start using the service")
    end
  end
end
