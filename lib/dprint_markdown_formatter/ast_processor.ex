defmodule DprintMarkdownFormatter.AstProcessor do
  @moduledoc """
  AST processing utilities for extracting and formatting module attributes.

  Handles parsing Elixir source code, identifying module attributes that contain
  markdown content, and creating patches to apply formatted content back to the
  source.
  """

  alias DprintMarkdownFormatter.Config
  alias DprintMarkdownFormatter.Error
  alias DprintMarkdownFormatter.PatchBuilder
  alias DprintMarkdownFormatter.StringUtils

  @typep ast :: Macro.t()
  @typep patches :: [Sourceror.Patch.t()]

  @doc """
  Parses Elixir source content into an AST.

  Returns `{:ok, ast}` on success, or `{:error, error}` if parsing fails.
  """
  @spec parse_elixir_source(String.t()) :: {:ok, ast()} | {:error, Exception.t()}
  def parse_elixir_source(content) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        {:ok, ast}

      {:error, error} ->
        {:error, Error.parse_error("Failed to parse Elixir source", original_error: error)}
    end
  end

  @doc """
  Applies patches to source content and performs final cleanup.

  Returns `{:ok, patched_content}` on success, or `{:error, error}` if patching
  fails.
  """
  @spec apply_patches(String.t(), patches()) ::
          {:ok, String.t()} | {:error, Exception.t()}
  def apply_patches(content, patches) do
    patched_content =
      content
      |> Sourceror.patch_string(patches)
      |> StringUtils.final_cleanup_whitespace()

    {:ok, patched_content}
  rescue
    error -> {:error, Error.format_error("Failed to apply patches", original_error: error)}
  end

  @doc """
  Collects patches for formatting module attributes containing markdown.

  Walks the AST and creates patches for any attributes in `doc_attributes` that
  contain markdown content needing formatting.
  """
  @spec collect_patches_for_doc_attributes(ast(), [atom()], Config.t()) ::
          {:ok, patches()} | {:error, Exception.t()}
  def collect_patches_for_doc_attributes(ast, doc_attributes, config) do
    {_updated_ast, patches} =
      Macro.postwalk(ast, [], fn node, acc ->
        process_node_for_patches(node, doc_attributes, config, acc)
      end)

    {:ok, patches}
  rescue
    error -> {:error, Error.format_error("Failed to collect patches", original_error: error)}
  end

  @doc """
  Processes a single AST node to determine if it needs patching.

  Identifies module attribute nodes that match the target attributes and contain
  markdown content, then creates appropriate patches.
  """
  @spec process_node_for_patches(ast(), [atom()], Config.t(), patches()) :: {ast(), patches()}
  def process_node_for_patches(node, doc_attributes, config, acc) do
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

  @doc """
  Creates a patch for formatted content if the attribute should be processed.

  Formats the markdown content and creates a source patch if the content changed.
  """
  @spec create_patch_for_formatted_content(ast(), String.t(), ast(), keyword(), patches()) ::
          {ast(), patches()}
  def create_patch_for_formatted_content(node, formatted, string_node, block_meta, acc) do
    range = Sourceror.get_range(string_node)
    delimiter = block_meta[:delimiter] || "\"\"\""
    replacement = PatchBuilder.build_replacement_string(formatted, delimiter)

    patch = %Sourceror.Patch{
      range: range,
      change: replacement
    }

    {node, [patch | acc]}
  end

  # Private functions

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
