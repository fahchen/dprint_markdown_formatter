defmodule DprintMarkdownFormatter.SigilAttributeTest do
  use ExUnit.Case, async: true

  @moduletag :sigil_attributes

  describe "~S sigil support in module attributes" do
    test "formats @moduledoc with ~S\"\"\" delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Header   with   spaces

        This is   a   paragraph   with   irregular   spacing.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Header with spaces

        This is a paragraph with irregular spacing.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S/ delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S/
        # Header   with   spaces

        This is   a   paragraph   with   irregular   spacing.
        /
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S/
        # Header with spaces

        This is a paragraph with irregular spacing.
        /
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S| delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S|
        # Header   with   spaces

        This is   a   paragraph   with   irregular   spacing.
        |
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S|
        # Header with spaces

        This is a paragraph with irregular spacing.
        |
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S\" delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"# Header   with   spaces\n\nThis is   a   paragraph."
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"# Header with spaces\n\nThis is a paragraph."
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S' delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S'# Header   with   spaces

        This is   a   paragraph.'
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S'
        # Header with spaces

        This is a paragraph.
        '
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S() delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S(
        # Header   with   spaces

        This is   a   paragraph.
        )
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S(
        # Header with spaces

        This is a paragraph.
        )
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S[] delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S[
        # Header   with   spaces

        This is   a   paragraph.
        ]
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S[
        # Header with spaces

        This is a paragraph.
        ]
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S{} delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S{
        # Header   with   spaces

        This is   a   paragraph.
        }
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S{
        # Header with spaces

        This is a paragraph.
        }
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~S<> delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S<
        # Header   with   spaces

        This is   a   paragraph.
        >
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S<
        # Header with spaces

        This is a paragraph.
        >
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "~s sigil support in module attributes (with interpolation)" do
    test "formats @moduledoc with ~s\"\"\" delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~s"""
        # Header   with   spaces

        This is   a   paragraph   with   irregular   spacing.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~s"""
        # Header with spaces

        This is a paragraph with irregular spacing.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~s/ delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~s/# Header   with   spaces\n\nThis is   a   paragraph./
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~s/# Header with spaces\n\nThis is a paragraph./
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @moduledoc with ~s| delimiter" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~s|# Header   with   spaces\n\nThis is   a   paragraph.|
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~s|# Header with spaces\n\nThis is a paragraph.|
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "sigil support for other module attributes" do
    test "formats @doc with ~S\"\"\" delimiter" do
      input = ~S'''
      defmodule Example do
        @doc ~S"""
        This function   does   something   important.

        ## Parameters
        - **param1** - The   first   parameter
        """
        def my_function(param1), do: param1
      end
      '''

      expected = ~S'''
      defmodule Example do
        @doc ~S"""
        This function does something important.

        ## Parameters

        - **param1** - The first parameter
        """
        def my_function(param1), do: param1
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @typedoc with ~S\"\"\" delimiter" do
      input = ~S'''
      defmodule Example do
        @typedoc ~S"""
        This type   represents   something   important.

        Used for   various   purposes.
        """
        @type my_type :: atom()
      end
      '''

      expected = ~S'''
      defmodule Example do
        @typedoc ~S"""
        This type represents something important.

        Used for various purposes.
        """
        @type my_type :: atom()
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @shortdoc with ~S delimiter" do
      input = ~S'''
      defmodule Example do
        @shortdoc ~S"This is   a   short   description"
      end
      '''

      expected = ~S'''
      defmodule Example do
        @shortdoc ~S"This is a short description"
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats @deprecated with ~S delimiter" do
      input = ~S'''
      defmodule Example do
        @deprecated ~S"This function   is   deprecated   for   reasons"
        def old_function, do: :ok
      end
      '''

      expected = ~S'''
      defmodule Example do
        @deprecated ~S"This function is deprecated for reasons"
        def old_function, do: :ok
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "mixed sigil and regular string scenarios" do
    test "handles mix of regular strings and sigils in same file" do
      input = ~S'''
      defmodule Example do
        @moduledoc """
        Regular   heredoc   with   spaces.
        """

        @doc ~S"""
        Sigil   heredoc   with   spaces.
        """
        def my_function, do: :ok

        @typedoc "Regular   simple   string."
        @type my_type :: atom()

        @shortdoc ~S"Sigil   simple   string."
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc """
        Regular heredoc with spaces.
        """

        @doc ~S"""
        Sigil heredoc with spaces.
        """
        def my_function, do: :ok

        @typedoc "Regular simple string."
        @type my_type :: atom()

        @shortdoc ~S"Sigil simple string."
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "edge cases and error handling" do
    test "preserves sigil syntax when formatting fails" do
      # This should not crash and should preserve original content
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        Some   malformed   markdown   that   might   cause   issues
        :::invalid-syntax:::
        """
      end
      '''

      # Even if formatting fails, the sigil syntax should be preserved
      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert String.contains?(result, "~S\"\"\"")
      assert String.contains?(result, ":::invalid-syntax:::")
    end

    test "handles nested delimiters correctly" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        This contains   "quotes"   inside   the   sigil.
        And   ```code   blocks```   too.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        This contains "quotes" inside the sigil. And `code   blocks` too.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  describe "sigils with markdown block elements" do
    test "formats code blocks within ~S sigils" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # API   Documentation

        Here's   an   example:

        ```elixir
        def   hello   do
          :world
        end
        ```

        More   text   here.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # API Documentation

        Here's an example:

        ```elixir
        def   hello   do
          :world
        end
        ```

        More text here.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats blockquotes within ~S sigils" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Important   Note

        > This   is   a   blockquote   with   extra   spaces.
        > It   should   be   formatted   properly.

        Regular   text   follows.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Important Note

        > This is a blockquote with extra spaces. It should be formatted properly.

        Regular text follows.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats lists within ~S sigils" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Features

        *   First   feature   with   spaces
        *   Second   feature
            *   Nested   item   with   spaces
            *   Another   nested   item
        *   Third   feature

        ## Numbered   List

        1.   Step   one   with   spaces
        2.   Step   two
             1.   Sub-step   with   spaces
             2.   Another   sub-step
        3.   Step   three
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Features

        - First feature with spaces
        - Second feature
          - Nested item with spaces
          - Another nested item
        - Third feature

        ## Numbered List

        1. Step one with spaces
        2. Step two
           1. Sub-step with spaces
           2. Another sub-step
        3. Step three
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats tables within ~S sigils" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Data   Format

        | Column   1 | Column   2   | Column   3 |
        |---|---|---|
        | Value   A   | Value   B | Value   C |
        |Value   D|Value   E|Value   F|

        More   text   after   table.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~S"""
        # Data Format

        | Column 1 | Column 2 | Column 3 |
        | -------- | -------- | -------- |
        | Value A  | Value B  | Value C  |
        | Value D  | Value E  | Value F  |

        More text after table.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats complex nested markdown within ~s sigils" do
      input = ~S'''
      defmodule Example do
        @moduledoc ~s"""
        # Complex   Example

        This   has   **bold   text**   and   *italic   text*.

        > **Important:**   This   is   a   blockquote   with   emphasis.
        >
        > ```elixir
        > def   example   do
        >   :ok
        > end
        > ```

        ## List   with   code

        *   First   item   with   `inline   code`
        *   Second   item:
            ```bash
            mix   deps.get
            mix   compile
            ```
        *   Third   item

        | Function | Purpose |
        |---|---|
        |`start/0`|Starts   the   application|
        |`stop/0`|Stops   it|
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @moduledoc ~s"""
        # Complex Example

        This has **bold text** and *italic text*.

        > **Important:** This is a blockquote with emphasis.
        >
        > ```elixir
        > def   example   do
        >   :ok
        > end
        > ```

        ## List with code

        - First item with `inline   code`
        - Second item:
          ```bash
          mix   deps.get
          mix   compile
          ```
        - Third item

        | Function  | Purpose                |
        | --------- | ---------------------- |
        | `start/0` | Starts the application |
        | `stop/0`  | Stops it               |
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "preserves code block content formatting within ~S sigils" do
      input = ~S'''
      defmodule Example do
        @doc ~S"""
        Example   usage:

        ```elixir
        # This   code   should   maintain   its   internal   formatting
        def   my_function(param1,   param2) do
          if   param1   ==   :special do
            {:ok,   param2}
          else
            {:error,   :invalid}
          end
        end
        ```

        The   surrounding   text   gets   formatted.
        """
      end
      '''

      expected = ~S'''
      defmodule Example do
        @doc ~S"""
        Example usage:

        ```elixir
        # This   code   should   maintain   its   internal   formatting
        def   my_function(param1,   param2) do
          if   param1   ==   :special do
            {:ok,   param2}
          else
            {:error,   :invalid}
          end
        end
        ```

        The surrounding text gets formatted.
        """
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "formats doctests within ~S sigils" do
      input = ~S'''
      defmodule Example do
        @doc ~S"""
        Converts   double-quotes   to   single-quotes.

        ## Examples

            iex>   convert("\"foo\"")
            "'foo'"

        More   examples:

            iex>   convert("\"bar\"   and   \"baz\"")
            "'bar'   and   'baz'"

            iex>   convert("")
            ""

        """
        def convert(text), do: String.replace(text, "\"", "'")
      end
      '''

      expected = ~S'''
      defmodule Example do
        @doc ~S"""
        Converts double-quotes to single-quotes.

        ## Examples

            iex>   convert("\"foo\"")
            "'foo'"

        More examples:

            iex>   convert("\"bar\"   and   \"baz\"")
            "'bar'   and   'baz'"

            iex>   convert("")
            ""
        """
        def convert(text), do: String.replace(text, "\"", "'")
      end
      '''

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end

    test "handles code blocks with triple quotes inside ~S sigils" do
      input =
        trim_leading_spaces(
          ~S{
          defmodule Example do
            @moduledoc ~S'''
            This module demonstrates
            heredoc usage.

            ## Code Example
            ```elixir
            defmodule   MyModule do
              @moduledoc   """
              This   is   a   nested   heredoc   inside   a   code   block.
              It   should   not   interfere   with   the   outer   sigil.
              """

              def   example do
                text = """
                Triple   quoted   string   inside   function.
                More   content   here.
                """
                String.trim(text)
              end
            end
            ```


            The surrounding text gets formatted.
            '''
          end
          },
          10
        )

      expected =
        trim_leading_spaces(
          ~S{defmodule Example do
            @moduledoc ~S'''
            This module demonstrates heredoc usage.

            ## Code Example

            ```elixir
            defmodule   MyModule do
              @moduledoc   """
              This   is   a   nested   heredoc   inside   a   code   block.
              It   should   not   interfere   with   the   outer   sigil.
              """

              def   example do
                text = """
                Triple   quoted   string   inside   function.
                More   content   here.
                """
                String.trim(text)
              end
            end
            ```

            The surrounding text gets formatted.
            '''
          end
          },
          10
        )

      result = DprintMarkdownFormatter.format(input, extension: ".ex")
      assert result == expected
    end
  end

  defp trim_leading_spaces(input, length) do
    leading_spaces = String.duplicate(" ", length)

    input
    |> String.split("\n")
    |> Enum.map(&String.trim_leading(&1, leading_spaces))
    |> Enum.join("\n")
  end
end
