defmodule TestModule do
  @moduledoc """
  #    Main Module Documentation

  This is a **comprehensive**    test module that demonstrates various markdown features:

  -   Unordered lists with *emphasis*
  -    Code blocks and `inline code`
  -  [Links](https://example.com) and references

  ##    Features

  1.   Numbered lists
  2.  Multiple paragraphs
  3.    Various formatting options

  >   Blockquotes for important information

  ###   Code Examples

  ```elixir
  def example_function do
    :ok
  end
  ```
  """

  @doc """
  #   Function Documentation

  This function demonstrates **bold text**   and _italic text_  formatting.

  ##  Parameters

  -  `param1` - The first parameter with `inline code`
  -   `param2` - Second parameter

  ##   Examples

      iex> TestModule.example_function(:test)
      :ok

  ##  Returns

  Returns `:ok`   when successful.
  """
  @spec example_function(any(), any()) :: :ok
  def example_function(param1, param2 \\ nil) do
    :ok
  end

  @typedoc """
  #  Custom Type Documentation

  This type represents various states:

  *  `:active` - When the system is running
  *   `:inactive` - When stopped  
  *  `:error` - When something went wrong

  See the [official docs](https://hexdocs.pm)  for more details.
  """
  @type status :: :active | :inactive | :error

  @shortdoc """
  A **short**   description with *emphasis*  and `code`.
  """

  @deprecated """
  Use `new_function/2`  instead.

  This function is deprecated because:

  1.  It has security issues
  2.   Performance is poor
  3.  Better alternatives exist

  See the [migration guide](https://example.com/migrate)   for details.
  """
  @spec old_function() :: :legacy
  def old_function do
    :legacy
  end
end
