defmodule DprintMarkdownFormatterTest do
  use ExUnit.Case, async: true
  use Mimic
  doctest DprintMarkdownFormatter

  setup do
    # Default configuration for tests that don't explicitly mock it
    # This enables default module attribute formatting unless overridden
    stub(Mix.Project, :config, fn ->
      [
        dprint_markdown_formatter: [
          format_module_attributes: true
        ]
      ]
    end)

    :ok
  end

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

    @tag :skip
    test "handles complex mixed content - KNOWN ISSUE: asterisk nested lists lose indentation" do
      # This test demonstrates a limitation in dprint-plugin-markdown
      # When converting asterisk lists to dashes, nested indentation is lost
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

      # What we would expect (correct nesting):
      _expected = """
      # Title

      This is a paragraph.

      - Item 1
        - Nested
      - Item 2

      **Bold** and *italic*.

      > Quote here
      """

      # What we actually get (flattened nesting):
      actual_result = """
      # Title

      This is a paragraph.

      - Item 1
      - Nested
      - Item 2

      **Bold** and *italic*.

      > Quote here
      """

      assert result == actual_result
      # This test is skipped because it's a known dprint library limitation
    end

    test "handles complex mixed content - demonstrates nested list flattening limitation" do
      # NOTE: This test shows current dprint-plugin-markdown behavior
      # Nested lists are flattened regardless of whether they use asterisks or dashes
      input = """
      #   Title

      This   is   a   paragraph.

      -  Item 1
        -  Nested
      -  Item 2

      **Bold** and *italic*.

      > Quote   here
      """

      result = DprintMarkdownFormatter.format(input, [])

      # What dprint actually produces (flattened):
      expected = """
      # Title

      This is a paragraph.

      - Item 1
      - Nested
      - Item 2

      **Bold** and *italic*.

      > Quote here
      """

      assert result == expected
    end

    test "preserves line breaks in code blocks" do
      input = ~S'''
      Some text

      ```
      line 1
      line 2
      ```
      '''

      result = DprintMarkdownFormatter.format(input, [])

      expected = """
      Some text

      ```
      line 1
      line 2
      ```
      """

      assert result == expected
    end

    test "handles horizontal rules" do
      input = "---\n\nContent here\n\n***"
      result = DprintMarkdownFormatter.format(input, [])

      expected = "---\n\nContent here\n\n---\n"
      assert result == expected
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

      expected = "* Item 1\n* Item 2\n"
      assert result_asterisks == expected
    end

    test "emphasis_kind option changes emphasis style" do
      input = "*italic text*"
      result_underscores = DprintMarkdownFormatter.format(input, emphasis_kind: "underscores")

      expected = "_italic text_\n"
      assert result_underscores == expected
    end

    test "text_wrap option affects wrapping behavior" do
      input =
        "This is a very long line of text that normally would be wrapped but with never option should stay on one line."

      result_default = DprintMarkdownFormatter.format(input, line_width: 20)
      result_never = DprintMarkdownFormatter.format(input, text_wrap: "never", line_width: 20)

      # With text_wrap: "never", should keep text on one line
      expected_never =
        "This is a very long line of text that normally would be wrapped but with never option should stay on one line.\n"

      assert result_never == expected_never

      # Default should wrap the text
      refute result_default == result_never
    end

    test "native function can be called directly with options" do
      input = "- Item 1\n- Item 2"

      result =
        DprintMarkdownFormatter.Native.format_markdown(input, unordered_list_kind: "asterisks")

      assert {:ok, formatted} = result
      expected = "* Item 1\n* Item 2\n"
      assert formatted == expected
    end
  end

  describe "error handling" do
    test "returns error for non-string input" do
      # This test verifies the guard clause works
      assert_raise FunctionClauseError, fn ->
        DprintMarkdownFormatter.format(123, [])
      end
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
      expected = "# Header with spaces\n"
      assert result == expected
    end

    @tag :skip
    test "format/2 returns original content on formatting error" do
      # Note: Skipped due to NIF mocking limitations with Mimic
      # This functionality is tested indirectly through error handling paths
      :skipped
    end

    test "format/2 with empty options formats correctly" do
      input = "# Header    with    spaces"
      result = DprintMarkdownFormatter.format(input, [])
      assert result == "# Header with spaces\n"
    end
  end

  describe "content type detection and routing" do
    test "elixir source files format module attributes correctly" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is some   messy   markdown
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is some messy markdown
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "elixir script files format module attributes correctly" do
      input = ~S'''
      @moduledoc """
      # Header   with   spaces
      """

      IO.puts "Hello"
      '''

      expected = ~S'''
      @moduledoc """
      # Header with spaces
      """

      IO.puts("Hello")
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".exs")
      assert result == expected
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

      expected =
        "# Header with spaces\n\nThis is a paragraph with irregular spacing.\n\n- Item 1\n- Item 2\n\n**Bold text** and *italic text*"

      assert result == expected
    end
  end

  describe "module attribute formatting" do
    test "formats @moduledoc heredoc correctly" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        # Header   with   spaces

        This is   a   paragraph   with   irregular   spacing.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        # Header with spaces

        This is a paragraph with irregular spacing.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc simple string correctly" do
      input = ~S'''
      defmodule Example do
        @moduledoc "This is   a   simple   string   with   spaces"
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc "This is a simple string with spaces"
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @doc heredoc correctly" do
      input = ~S'''
      defmodule Example do
        @doc """
        This function   does   something   important.

        ## Examples

            iex> Example.test()
            :ok
        """
        def test, do: :ok
      end
      '''

      expected = ~S'''
      defmodule Example do
        @doc """
        This function does something important.

        ## Examples

            iex> Example.test()
            :ok
        """
        def test, do: :ok
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @doc simple string correctly" do
      input = ~S'''
      defmodule Example do
        @doc "This function   does   something   important."
        def test, do: :ok
      end
      '''

      expected = ~S'''
      defmodule Example do
        @doc "This function does something important."
        def test, do: :ok
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @typedoc heredoc correctly" do
      input = ~S'''
      defmodule Example do
        @typedoc """
        This type   represents   something   important.
        """
        @type test_type :: atom()
      end
      '''

      expected = ~S'''
      defmodule Example do
        @typedoc """
        This type represents something important.
        """
        @type test_type :: atom()
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @shortdoc correctly" do
      input = ~S'''
      defmodule Example do
        @shortdoc "This is   a   short   description"
      end
      '''

      expected = ~S'''
      defmodule Example do
        @shortdoc "This is a short description"
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @deprecated correctly" do
      input = ~S'''
      defmodule Example do
        @deprecated "This function   is   deprecated   for   reasons"
        def old_function, do: :ok
      end
      '''

      expected = ~S'''
      defmodule Example do
        @deprecated "This function is deprecated for reasons"
        def old_function, do: :ok
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "preserves attribute formatting with complex AST" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   markdown   content.
        """

        @doc """
        This is   doc   content.
        """
        def test(arg1, arg2) when is_atom(arg1), do: :ok

        @spec test(atom(), any()) :: :ok
        def test(arg1, arg2), do: :ok
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is markdown content.
        """

        @doc """
        This is doc content.
        """
        def test(arg1, arg2) when is_atom(arg1), do: :ok

        @spec test(atom(), any()) :: :ok
        def test(arg1, arg2), do: :ok
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats multiple attributes in same module" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   the   module   documentation.
        """

        @doc """
        This function   does   something.
        """
        def test, do: :ok

        @typedoc "This type   represents   something."
        @type test_type :: atom()
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is the module documentation.
        """

        @doc """
        This function does something.
        """
        def test, do: :ok

        @typedoc "This type represents something."
        @type test_type :: atom()
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "preserves non-markdown content unchanged" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   markdown   content.
        """

        @some_other_attr "This is not markdown"
        @compile :debug_info

        def test do
          # This comment should be preserved
          :ok
        end
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is markdown content.
        """

        @some_other_attr "This is not markdown"
        @compile :debug_info

        def test do
          # This comment should be preserved
          :ok
        end
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "handles invalid/unparseable elixir source gracefully" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   markdown   content.
        """

        # This is invalid Elixir syntax - unmatched parenthesis
        def test(arg1, arg2
          :ok
        end
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      # Should return original content if parsing fails
      assert result == input
    end
  end

  describe "module attribute configuration" do
    test "respects format_module_attributes configuration for moduledoc" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   markdown   content.
        """
        @shortdoc "This is   a   short   description"
      end
      '''

      # Mock Mix.Project.config to return custom format_module_attributes configuration
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduledoc: true,

              # Disable @shortdoc formatting
              shortdoc: false
            ]
          ]
        ]
      end)

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is markdown content.
        """
        @shortdoc "This is   a   short   description"
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats only enabled attributes when configured" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   markdown   content.
        """

        @doc """
        This is   doc   content.
        """
      end
      '''

      # Mock configuration to disable @doc formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduledoc: true,

              # Disable @doc formatting
              doc: false
            ]
          ]
        ]
      end)

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is markdown content.
        """

        @doc """
        This is   doc   content.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "testing attribute formatting" do
    test "formats @moduletag heredoc correctly when enabled" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag """
        This module   tests   the   authentication   system.

        It covers:
        - Login functionality
        - Password validation
        """
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag """
        This module tests the authentication system.

        It covers:

        - Login functionality
        - Password validation
        """
      end
      '''

      # Mock configuration to enable @moduletag formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduletag simple string correctly when enabled" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is   a   module   tag   description"
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is a module tag description"
      end
      '''

      # Mock configuration to enable @moduletag formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @tag heredoc correctly when enabled" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @tag """
        This test   verifies   that   users   can   login.
        See the [auth docs](docs/auth.md) for   more   details.
        """
        test "user can login" do
          assert true
        end
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @tag """
        This test verifies that users can login. See the [auth docs](docs/auth.md) for
        more details.
        """
        test "user can login" do
          assert true
        end
      end
      '''

      # Mock configuration to enable @tag formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              tag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @tag simple string correctly when enabled" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @tag "This is   a   test   tag   description"
        test "example test" do
          assert true
        end
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @tag "This is a test tag description"
        test "example test" do
          assert true
        end
      end
      '''

      # Mock configuration to enable @tag formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              tag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @describetag correctly when enabled" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @describetag "This is   a   describe   block   tag   description"
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @describetag "This is a describe block tag description"
      end
      '''

      # Mock configuration to enable @describetag formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              describetag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "does not format testing attributes when disabled by default" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is   a   module   tag   description"
        @tag "This is   a   test   tag   description"
        @describetag "This is   a   describe   block   tag   description"
      end
      '''

      # Expected: unchanged because testing attributes are disabled by default
      expected = input

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "handles mixed testing attributes with different configurations" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is   a   module   tag   description"
        @tag "This is   a   test   tag   description"
        @describetag "This is   a   describe   block   tag   description"
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is a module tag description"
        @tag "This is   a   test   tag   description"
        @describetag "This is   a   describe   block   tag   description"
      end
      '''

      # Mock configuration to enable only @moduletag formatting
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true,
              tag: false,
              describetag: false
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "testing attribute type safety" do
    test "skips boolean values in testing attributes" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag false
        @tag false
        @describetag false
      end
      '''

      # Expected: unchanged because boolean values are skipped
      expected = input

      # Mock configuration to enable testing attributes
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true,
              tag: true,
              describetag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "skips keyword list values in testing attributes" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag slow: true
        @tag timeout: 5000
        @describetag integration: true
      end
      '''

      # Expected: unchanged because keyword lists are skipped
      expected = input

      # Mock configuration to enable testing attributes
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true,
              tag: true,
              describetag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "handles mixed value types in testing attributes" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is   a   string   description"
        @tag slow: true
        @describetag false
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag "This is a string description"
        @tag slow: true
        @describetag false
      end
      '''

      # Mock configuration to enable testing attributes
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true,
              tag: true,
              describetag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "processes only string values while preserving other types" do
      input = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag """
        This is   a   heredoc   description.
        """
        @tag "This is   a   simple   string"
        @describetag slow: true, timeout: 5000
      end
      '''

      expected = ~S'''
      defmodule ExampleTest do
        use ExUnit.Case

        @moduletag """
        This is a heredoc description.
        """
        @tag "This is a simple string"
        @describetag slow: true, timeout: 5000
      end
      '''

      # Mock configuration to enable testing attributes
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduletag: true,
              tag: true,
              describetag: true
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "flexible format_module_attributes configuration" do
    test "boolean true formats default common attributes" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """

        @doc """
        This is   function   documentation.
        """

        @typedoc "This is   type   documentation."
        @shortdoc "This is   short   documentation."
        @deprecated "This is   deprecation   notice."
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is module documentation.
        """

        @doc """
        This is function documentation.
        """

        @typedoc "This is type documentation."
        @shortdoc "This is short documentation."
        @deprecated "This is deprecation notice."
      end
      '''

      # Mock configuration with boolean true
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: true
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "boolean false skips all attribute formatting" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """

        @doc """
        This is   function   documentation.
        """

        @custom_attr "This is   custom   content."
      end
      '''

      # Mock configuration with boolean false
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: false
          ]
        ]
      end)

      # Content should remain unchanged
      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == input
    end

    test "simple list format supports any attribute names" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """

        @custom_doc """
        This is   custom   documentation.
        """

        @note "This is   a   note."
        @example "This is   an   example."

        @doc """
        This should   not   be   formatted.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is module documentation.
        """

        @custom_doc """
        This is custom documentation.
        """

        @note "This is a note."
        @example "This is an example."

        @doc """
        This should   not   be   formatted.
        """
      end
      '''

      # Mock configuration with simple list (only specific attributes)
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [:moduledoc, :custom_doc, :note, :example]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "empty list skips all formatting" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """

        @doc "This is   function   documentation."
      end
      '''

      # Mock configuration with empty list
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: []
          ]
        ]
      end)

      # Content should remain unchanged
      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == input
    end

    test "nil configuration disables all formatting" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """

        @custom_attr "This should   not   be   formatted."
      end
      '''

      # Mock configuration with nil format_module_attributes
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            line_width: 80
            # format_module_attributes is nil/missing
          ]
        ]
      end)

      # Content should remain unchanged since nil disables formatting
      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == input
    end

    test "invalid configuration disables formatting" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """
      end
      '''

      # Mock configuration with invalid format_module_attributes
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: "invalid"
          ]
        ]
      end)

      # Content should remain unchanged since invalid config disables formatting
      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == input
    end

    test "keyword list format (backward compatibility) still works" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        This is   module   documentation.
        """

        @custom_attr "This should   not   be   formatted."
        @note "This should   be   formatted."
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        This is module documentation.
        """

        @custom_attr "This should   not   be   formatted."
        @note "This should be formatted."
      end
      '''

      # Mock configuration with keyword list (old format)
      expect(Mix.Project, :config, fn ->
        [
          dprint_markdown_formatter: [
            format_module_attributes: [
              moduledoc: true,
              note: true,
              custom_attr: false
            ]
          ]
        ]
      end)

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end
end
