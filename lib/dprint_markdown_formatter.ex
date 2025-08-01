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
            text_wrap: :never,
            emphasis_kind: :underscores,

            # Enable formatting for default attributes (moduledoc, doc, typedoc, shortdoc, deprecated)
            format_module_attributes: true,

            # Or disable all formatting (default behavior)
            # format_module_attributes: nil,

            # Or specify custom attributes
            # format_module_attributes: [:moduledoc, :doc, :custom_doc, :note]
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

  **Note:** Configuration values can be provided as atoms (`:never`) or strings (`"never"`). 
  Atoms are preferred for consistency with Elixir conventions.
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

    Only string values are processed (boolean `false` values are preserved
    unchanged). Use `default_doc_attributes/0` to get the standard list.

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

  require Logger

  alias DprintMarkdownFormatter.Config
  alias DprintMarkdownFormatter.Error
  alias DprintMarkdownFormatter.StringUtils
  alias DprintMarkdownFormatter.Validator

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
  Mix.Tasks.Format implementation.

  This is the actual function used by Mix formatter. It calls `format_with_errors/2` internally
  and returns the original content if formatting fails.

  ## Examples

      iex> DprintMarkdownFormatter.format("# Hello    World", [])
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("# Hello    World", extension: ".md")
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("# Hello    World", sigil: :M)
      "# Hello World"

      iex> DprintMarkdownFormatter.format("# Hello    World", line_width: 60)
      "# Hello World\\n"

      iex> DprintMarkdownFormatter.format("* Item 1\\n* Item 2", unordered_list_kind: :asterisks)
      "* Item 1\\n* Item 2\\n"
  """
  @impl Mix.Tasks.Format
  @spec format(String.t(), keyword()) :: String.t()
  def format(contents, opts) when is_binary(contents) and is_list(opts) do
    case format_with_errors(contents, opts) do
      {:ok, formatted} -> formatted
      {:error, _error} -> contents
    end
  end

  @doc """
  Formats markdown text with error details.

  Returns `{:ok, formatted_content}` on success, or `{:error, error}` on failure.
  This provides more detailed error information than the `Mix.Tasks.Format` version.

  ## Examples

      iex> DprintMarkdownFormatter.format_with_errors("# Hello    World", [])
      {:ok, "# Hello World\\n"}

      iex> DprintMarkdownFormatter.format_with_errors("# Hello", line_width: 100)
      {:ok, "# Hello\\n"}

      # Error cases return detailed error information (e.g., invalid content types)
      # {:error, %DprintMarkdownFormatter.Error.ValidationError{}} would be returned for invalid inputs
  """
  @spec format_with_errors(String.t(), keyword()) :: {:ok, String.t()} | {:error, Error.t()}
  def format_with_errors(contents, opts) when is_binary(contents) and is_list(opts) do
    with {:ok, validated_contents} <- Validator.validate_content(contents),
         {:ok, validated_opts} <- Validator.validate_options(opts),
         {:ok, content_type} <- determine_content_type(validated_opts),
         {:ok, formatted} <- do_format(content_type, validated_contents, validated_opts) do
      {:ok, formatted}
    else
      {:error, _error} = error_result ->
        error_result
    end
  end

  @doc """
  Returns the default list of module attributes that are formatted when
  `format_module_attributes: true`.

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
    Config.default_doc_attributes()
  end

  # Private helpers

  defp determine_content_type(opts) do
    content_type =
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

    {:ok, content_type}
  end

  defp do_format(:markdown, contents, opts), do: format_markdown(contents, opts)
  defp do_format(:elixir_source, contents, opts), do: format_elixir_source(contents, opts)
  defp do_format(:sigil, contents, opts), do: format_sigil(contents, opts)

  defp format_markdown(contents, opts) do
    with {:ok, config} <- get_config(),
         {:ok, merged_config} <- merge_runtime_options(config, opts),
         {:ok, formatted} <- call_nif(contents, merged_config) do
      {:ok, formatted}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp format_sigil(contents, opts) do
    case format_markdown(contents, opts) do
      {:ok, formatted} ->
        # Remove trailing newline that dprint adds for consistency with sigil usage
        {:ok, String.trim_trailing(formatted, "\n")}

      {:error, _error} = error_result ->
        error_result
    end
  end

  defp format_elixir_source(contents, opts) do
    with {:ok, config} <- get_config(),
         {:ok, merged_config} <- merge_runtime_options(config, opts),
         doc_attributes <- Config.resolve_module_attributes(merged_config),
         {:ok, formatted_content} <-
           format_module_attributes(contents, doc_attributes, merged_config) do
      case Code.format_string!(formatted_content, opts) do
        [] -> {:ok, ""}
        formatted -> {:ok, IO.iodata_to_binary([formatted, ?\n])}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  defp get_config do
    config = Config.load()
    {:ok, config}
  rescue
    _error ->
      default_config = Config.default()
      {:ok, default_config}
  end

  defp merge_runtime_options(config, opts) do
    case Validator.validate_config(config) do
      {:ok, validated_config} ->
        try do
          {runtime_dprint_opts, _format_opts} =
            Keyword.split(opts, [
              :line_width,
              :text_wrap,
              :emphasis_kind,
              :strong_kind,
              :new_line_kind,
              :unordered_list_kind
            ])

          merged_config = Config.merge(validated_config, runtime_dprint_opts)
          Validator.validate_config(merged_config)
        rescue
          error ->
            {:error, Error.config_error("Failed to merge runtime options", original_error: error)}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp call_nif(contents, config) do
    nif_config = Config.to_nif_config(config)

    case DprintMarkdownFormatter.Native.format_markdown(contents, nif_config) do
      {:ok, formatted} ->
        {:ok, formatted}

      {:error, reason} ->
        {:error, Error.nif_error("NIF formatting failed", original_error: reason)}
    end
  end

  defp format_module_attributes(content, doc_attributes, config) do
    with {:ok, ast} <- parse_elixir_source(content),
         {:ok, patches} <- collect_patches_for_doc_attributes(ast, doc_attributes, config),
         {:ok, patched_content} <- apply_patches(content, patches) do
      {:ok, patched_content}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp parse_elixir_source(content) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        {:ok, ast}

      {:error, error} ->
        {:error, Error.parse_error("Failed to parse Elixir source", original_error: error)}
    end
  end

  defp apply_patches(content, patches) do
    patched_content =
      content
      |> Sourceror.patch_string(patches)
      |> StringUtils.final_cleanup_whitespace()

    {:ok, patched_content}
  rescue
    error -> {:error, Error.format_error("Failed to apply patches", original_error: error)}
  end

  defp collect_patches_for_doc_attributes(ast, doc_attributes, config) do
    {_updated_ast, patches} =
      Macro.postwalk(ast, [], fn node, acc ->
        process_node_for_patches(node, doc_attributes, config, acc)
      end)

    {:ok, patches}
  rescue
    error -> {:error, Error.format_error("Failed to collect patches", original_error: error)}
  end

  defp process_node_for_patches(node, doc_attributes, config, acc) do
    case node do
      # Handle both heredoc and simple string patterns: @moduledoc """content""" or @moduledoc "content"
      {:@, _meta, [{attr, _attr_meta, [{:__block__, block_meta, [doc_content]} = string_node]}]}
      when is_atom(attr) and is_binary(doc_content) ->
        process_doc_attribute(
          node,
          attr,
          doc_content,
          string_node,
          block_meta,
          doc_attributes,
          config,
          acc
        )

      _other_node ->
        {node, acc}
    end
  end

  defp process_doc_attribute(
         node,
         attr,
         doc_content,
         string_node,
         block_meta,
         doc_attributes,
         config,
         acc
       ) do
    if attr in doc_attributes do
      case format_markdown_content(doc_content, config) do
        {:ok, formatted} when formatted != doc_content ->
          create_patch_for_formatted_content(node, formatted, string_node, block_meta, acc)

        {:ok, _unchanged} ->
          {node, acc}

        {:error, _error} ->
          {node, acc}
      end
    else
      {node, acc}
    end
  end

  defp create_patch_for_formatted_content(node, formatted, string_node, block_meta, acc) do
    range = Sourceror.get_range(string_node)
    delimiter = block_meta[:delimiter] || "\"\"\""
    replacement = build_replacement_string(formatted, delimiter)

    patch = %Sourceror.Patch{
      range: range,
      change: replacement
    }

    {node, [patch | acc]}
  end

  defp build_replacement_string(formatted, delimiter) do
    if delimiter == "\"" do
      build_simple_string_replacement(formatted)
    else
      build_heredoc_replacement(formatted)
    end
  end

  defp build_simple_string_replacement(formatted) do
    if String.contains?(formatted, "\n") do
      # Convert to heredoc if content becomes multi-line
      indented_content = formatted
      "\"\"\"\n#{indented_content}\n\"\"\""
    else
      # Keep as simple string
      "\"#{formatted}\""
    end
  end

  defp build_heredoc_replacement(formatted) do
    # Heredoc format - preserve as heredoc
    indented_content = formatted

    "\"\"\"\n#{indented_content}\n\"\"\""
  end

  defp format_markdown_content(content, config) do
    nif_config = Config.to_nif_config(config)

    # Clean up content by removing leading indentation and normalizing empty lines
    clean_content = content

    case DprintMarkdownFormatter.Native.format_markdown(clean_content, nif_config) do
      {:ok, formatted} ->
        # For heredocs, remove the trailing newline that dprint adds
        # The heredoc structure will handle proper formatting
        {:ok, String.trim_trailing(formatted, "\n")}

      {:error, reason} ->
        {:error, Error.nif_error("Failed to format markdown content", original_error: reason)}
    end
  end
end
