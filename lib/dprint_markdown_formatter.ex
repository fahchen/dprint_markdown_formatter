defmodule DprintMarkdownFormatter do
  @moduledoc """
  A fast markdown formatter using dprint-plugin-markdown via Rustler NIF.

  This module provides an interface to format markdown text using the
  dprint-plugin-markdown formatter implemented in Rust for performance.

  ## Configuration

  Options for dprint can be configured in `mix.exs`:

      def project do
        [
          # ... other config
          dprint_markdown_formatter: [
            line_width: 100,
            text_wrap: "never",
            emphasis_kind: "underscores",

            # Enable formatting for default attributes (moduledoc, doc, typedoc, shortdoc, deprecated)
            format_module_attributes: true,

            # Or disable all formatting (default behavior)
            # format_module_attributes: nil,

            # Or specify custom attributes
            # format_module_attributes: [:moduledoc, :doc, :custom_doc, :note],

            # Or use keyword list (backward compatibility)
            # format_module_attributes: [moduledoc: true, shortdoc: false, custom_attr: true]
          ]
        ]
      end

  ### Available Options

  - `:line_width` - Maximum line width (default: 80)
  - `:text_wrap` - Text wrapping behavior: `:always`, `:never`, `:maintain`
    (default: `:always`)
  - `:emphasis_kind` - Emphasis style: `:asterisks`, `:underscores` (default:
    `:asterisks`)
  - `:strong_kind` - Strong text style: `:asterisks`, `:underscores` (default:
    `:asterisks`)
  - `:new_line_kind` - Line ending type: `:auto`, `:lf`, `:crlf` (default:
    `:auto`)
  - `:unordered_list_kind` - Unordered list style: `:dashes`, `:asterisks`
    (default: `:dashes`)
  - `:format_module_attributes` - Configure which module attributes to format.
    Supports four input types for maximum flexibility:

    **`nil` (default):** Skip formatting all module attributes.

    **Boolean `true`:** Format common documentation attributes: `:moduledoc`,
    `:doc`, `:typedoc`, `:shortdoc`, `:deprecated`

    **Boolean `false`:** Skip formatting all module attributes.

    **List of atoms:** Format only the specified attributes. Any module attribute
    containing string content can be specified. Examples:

        # Format only module docs
        format_module_attributes: [:moduledoc]

        # Format standard docs plus custom attributes  
        format_module_attributes: [:moduledoc, :doc, :custom_doc, :note, :example]

        # Format testing attributes
        format_module_attributes: [:moduletag, :tag, :describetag]

    **Keyword list (backward compatibility):** Use enabled/disabled flags:

        format_module_attributes: [moduledoc: true, shortdoc: false, custom_attr: true]

    Only string values are processed (boolean `false` and keyword lists are
    preserved unchanged). Use `default_doc_attributes/0` to get the standard list.

  ## Sigil Support

  For convenient markdown handling, you can use the ~M sigil:

      import DprintMarkdownFormatter.Sigil

      # Raw markdown
      markdown = ~M\"\"\"
      # Hello World

      Some content here.
      \"\"\"
  """

  @behaviour Mix.Tasks.Format

  @doc """
  Returns the features supported by this formatter plugin.

  This plugin supports:

  - The ~M sigil for markdown content
  - Files with .md and .markdown extensions (pure markdown)
  - Files with .ex and .exs extensions (module attributes only)
  """
  @impl Mix.Tasks.Format
  @spec features(keyword()) :: [sigils: [atom()], extensions: [binary()]]
  def features(_opts) do
    [sigils: [:M], extensions: [".md", ".markdown", ".ex", ".exs"]]
  end

  @doc """
  Formats markdown text using dprint-plugin-markdown.

  Returns the formatted string directly, or returns original content if formatting
  fails.

  ## Examples

      iex> DprintMarkdownFormatter.format("# Hello    World", [])
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("# Hello    World", extension: ".md")
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("# Hello    World", sigil: :M)
      "# Hello World"

      iex> DprintMarkdownFormatter.format("# Hello    World", line_width: 60)
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("* Item 1\\n* Item 2", unordered_list_kind: "asterisks")
      "* Item 1\\n* Item 2\\n"
  """
  @impl Mix.Tasks.Format
  @spec format(String.t(), keyword()) :: String.t()
  def format(contents, opts) when is_binary(contents) and is_list(opts) do
    case determine_content_type(opts) do
      :markdown ->
        format_markdown(contents, opts)

      :elixir_source ->
        format_elixir_source(contents, opts)

      :sigil ->
        format_sigil(contents, opts)
    end
  rescue
    _error ->
      # If formatting fails, return original content unchanged
      contents
  end

  @doc """
  Returns the default list of module attributes that are formatted when
  `doc_attributes: true`.

  This list includes the most commonly used documentation attributes in Elixir
  projects.

  ## Examples

      iex> DprintMarkdownFormatter.default_doc_attributes()
      [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated]

      # Extend with custom attributes
      custom_attrs = DprintMarkdownFormatter.default_doc_attributes() ++ [:custom_doc, :note]
  """
  @spec default_doc_attributes() :: [atom()]
  def default_doc_attributes do
    [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated]
  end

  # Private helpers

  defp determine_content_type(opts) do
    cond do
      Keyword.has_key?(opts, :sigil) ->
        :sigil

      Keyword.get(opts, :extension) in [".ex", ".exs"] ->
        :elixir_source

      Keyword.get(opts, :extension) in [".md", ".markdown"] ->
        :markdown

      true ->
        :markdown
    end
  end

  defp format_markdown(contents, opts) do
    config_opts = get_config_from_mix()

    {runtime_dprint_opts, _format_opts} =
      Keyword.split(opts, [
        :line_width,
        :text_wrap,
        :emphasis_kind,
        :strong_kind,
        :new_line_kind,
        :unordered_list_kind
      ])

    dprint_opts = Keyword.merge(config_opts, runtime_dprint_opts)

    case DprintMarkdownFormatter.Native.format_markdown(contents, dprint_opts) do
      {:ok, formatted} -> formatted
      {:error, _reason} -> contents
    end
  end

  defp format_sigil(contents, opts) do
    formatted = format_markdown(contents, opts)
    # Remove trailing newline that dprint adds for consistency with sigil usage
    String.trim_trailing(formatted, "\n")
  end

  defp format_elixir_source(contents, opts) do
    config = get_config_from_mix()
    doc_attributes = get_doc_attributes(config)

    # Extract dprint options
    {runtime_dprint_opts, _format_opts} =
      Keyword.split(opts, [
        :line_width,
        :text_wrap,
        :emphasis_kind,
        :strong_kind,
        :new_line_kind,
        :unordered_list_kind
      ])

    dprint_opts = Keyword.merge(config, runtime_dprint_opts)

    case format_module_attributes(contents, doc_attributes, dprint_opts) do
      {:ok, formatted_content} -> formatted_content
      {:error, _reason} -> contents
    end
  end

  defp get_config_from_mix do
    case Mix.Project.config()[:dprint_markdown_formatter] do
      nil -> []
      config when is_list(config) -> config
      _invalid -> []
    end
  end

  defp format_module_attributes(content, doc_attributes, dprint_opts) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        patches = collect_patches_for_doc_attributes(ast, doc_attributes, dprint_opts)
        patched_content = Sourceror.patch_string(content, patches)
        # Apply Elixir formatter to normalize indentation and structure
        formatted_content =
          try do
            result =
              patched_content
              |> Code.format_string!()
              |> IO.iodata_to_binary()

            # Ensure it ends with a newline
            if String.ends_with?(result, "\n") do
              result
            else
              result <> "\n"
            end
          rescue
            _ -> patched_content
          end

        {:ok, formatted_content}

      {:error, _error} ->
        {:error, :parse_error}
    end
  rescue
    error ->
      {:error, error}
  end

  defp collect_patches_for_doc_attributes(ast, doc_attributes, dprint_opts) do
    {_updated_ast, patches} =
      Macro.postwalk(ast, [], fn node, acc ->
        case node do
          # Handle both heredoc and simple string patterns: @moduledoc """content""" or @moduledoc "content"
          {:@, _meta,
           [{attr, _attr_meta, [{:__block__, block_meta, [doc_content]} = string_node]}]}
          when is_atom(attr) and is_binary(doc_content) ->
            if attr in doc_attributes do
              case format_markdown_content(doc_content, dprint_opts) do
                formatted when formatted != doc_content ->
                  # Get the range of just the string content, not the entire @moduledoc
                  range = Sourceror.get_range(string_node)
                  # Determine original format and preserve it
                  delimiter = block_meta[:delimiter] || "\"\"\""

                  replacement =
                    if delimiter == "\"" do
                      # Simple string format - keep as simple string if single line
                      if String.contains?(formatted, "\n") do
                        # Convert to heredoc if content becomes multi-line
                        indented_content = indent_content_for_heredoc(formatted)
                        "\"\"\"\n#{indented_content}\n  \"\"\""
                      else
                        # Keep as simple string
                        "\"#{formatted}\""
                      end
                    else
                      # Heredoc format - preserve as heredoc
                      indented_content = indent_content_for_heredoc(formatted)
                      "\"\"\"\n#{indented_content}\n  \"\"\""
                    end

                  patch = %Sourceror.Patch{
                    range: range,
                    change: replacement
                  }

                  {node, [patch | acc]}

                _unchanged ->
                  {node, acc}
              end
            else
              {node, acc}
            end

          _other_node ->
            {node, acc}
        end
      end)

    patches
  end

  defp indent_content_for_heredoc(content) do
    content
    |> String.split("\n")
    |> Enum.map_join("\n", fn line ->
      if String.trim(line) == "" do
        # Keep empty lines completely empty
        ""
      else
        # Add 2-space indentation to non-empty lines
        "  #{line}"
      end
    end)
  end

  defp format_markdown_content(content, dprint_opts) do
    case DprintMarkdownFormatter.Native.format_markdown(content, dprint_opts) do
      {:ok, formatted} ->
        # For heredocs, remove the trailing newline that dprint adds
        # The heredoc structure will handle proper formatting
        String.trim_trailing(formatted, "\n")

      {:error, _reason} ->
        content
    end
  end

  defp get_doc_attributes(config) do
    default_common_attributes = default_doc_attributes()

    case Keyword.get(config, :format_module_attributes) do
      # nil means disabled - no formatting
      nil ->
        []

      true ->
        default_common_attributes

      false ->
        []

      attrs when is_list(attrs) ->
        # Check if this is a keyword list (old format) or simple list (new format)
        if Keyword.keyword?(attrs) do
          # Old format: [moduledoc: true, tag: false] - filter enabled attributes
          attrs
          |> Enum.filter(fn {_attr, enabled} -> enabled end)
          |> Enum.map(fn {attr, _enabled} -> attr end)
        else
          # New format: [:moduledoc, :tag] - use as-is
          attrs
        end

      # Invalid config disables formatting
      _invalid ->
        []
    end
  end
end
