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

  **Note:** Configuration values can be provided as atoms (`:never`) or strings
  (`"never"`). Atoms are preferred for consistency with Elixir conventions.

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

  alias DprintMarkdownFormatter.AstProcessor
  alias DprintMarkdownFormatter.Config
  alias DprintMarkdownFormatter.Error
  alias DprintMarkdownFormatter.Validator

  # Dprint-specific configuration options (derived from Config struct fields plus Mix format options)
  @dprint_opts Config.__struct__()
               |> Map.from_struct()
               |> Map.keys()
               |> Kernel.++([:extension, :sigil])

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

  This is the actual function used by Mix formatter. It calls
  `format_with_errors/2` internally and returns the original content if formatting
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
  This provides more detailed error information than the `Mix.Tasks.Format`
  version.

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
    with {:ok, validated_opts} <- Validator.validate_options(opts),
         {:ok, content_type} <- determine_content_type(validated_opts),
         {:ok, formatted} <- do_format(content_type, contents, validated_opts) do
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
    content_type = determine_content_type_from_opts(opts)
    {:ok, content_type}
  end

  defp determine_content_type_from_opts(opts) do
    case {Keyword.has_key?(opts, :sigil), Keyword.get(opts, :extension)} do
      {true, _ext} -> :sigil
      {false, ext} when ext in [".ex", ".exs"] -> :elixir_source
      {false, ext} when ext in [".md", ".markdown"] -> :markdown
      {false, _ext} -> :markdown
    end
  end

  defp do_format(content_type, contents, opts) do
    case content_type do
      :markdown -> format_markdown(contents, opts)
      :elixir_source -> format_elixir_source(contents, opts)
      :sigil -> format_sigil(contents, opts)
    end
  end

  defp format_markdown(contents, opts) do
    with {:ok, config} <- get_config(),
         {:ok, merged_config} <- merge_runtime_options(config, opts),
         {:ok, formatted} <- call_nif(contents, merged_config) do
      {:ok, formatted}
    else
      {:error, _error} = error_result ->
        error_result
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
      # Remove dprint options to pass only valid Elixir formatter options
      elixir_opts = Keyword.drop(opts, @dprint_opts)

      case Code.format_string!(formatted_content, elixir_opts) do
        [] -> {:ok, ""}
        formatted -> {:ok, IO.iodata_to_binary([formatted, ?\n])}
      end
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
        # Only runtime dprint options (exclude format_module_attributes which is not a runtime option)
        runtime_dprint_keys = @dprint_opts -- [:format_module_attributes, :extension, :sigil]
        {runtime_dprint_opts, _format_opts} = Keyword.split(opts, runtime_dprint_keys)

        merged_config = Config.merge(validated_config, runtime_dprint_opts)
        Validator.validate_config(merged_config)

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
    with {:ok, ast} <- AstProcessor.parse_elixir_source(content),
         {:ok, patches} <-
           AstProcessor.collect_patches_for_doc_attributes(ast, doc_attributes, config),
         {:ok, patched_content} <- AstProcessor.apply_patches(content, patches) do
      {:ok, patched_content}
    else
      {:error, error} -> {:error, error}
    end
  end
end
