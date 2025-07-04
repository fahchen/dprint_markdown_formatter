# credo:disable-for-this-file
defmodule Mix.Tasks.Compile.MarkdownFormatter do
  @moduledoc """
  A compiler task that formats markdown content in module attributes.

  This task automatically formats markdown content in module attributes such as
  @moduledoc, @doc, @typedoc, @shortdoc, and @deprecated during compilation.

  ## Configuration

  The task can be configured in `mix.exs`:

      def project do
        [
          # ... other config
          dprint_markdown_formatter: [
            line_width: 100,
            text_wrap: "never",
            emphasis_kind: "underscores",
            format_attributes: [
              moduledoc: true,
              doc: true,
              typedoc: true,
              shortdoc: false,
              deprecated: true
            ]
          ]
        ]
      end

  ## Usage

  Add this task to your project's compilers in `mix.exs`:

      def project do
        [
          # ... other config
          compilers: [:markdown_formatter] ++ Mix.compilers()
        ]
      end

  The task will automatically format markdown content in supported attributes
  during the compilation process.
  """

  use Mix.Task.Compiler

  @recursive true
  @manifest "compile.markdown_formatter"

  @spec run(keyword()) :: :ok | :noop
  def run(opts) do
    config = get_config()
    format_attributes = get_format_attributes(config)

    if Enum.any?(format_attributes, fn {_attr, enabled} -> enabled end) do
      manifest = manifest_path(opts)
      sources = get_source_files()

      case check_if_formatting_needed(manifest, sources) do
        :noop ->
          :noop

        :ok ->
          format_sources(sources, format_attributes, config)
          write_manifest(manifest, sources)
          :ok
      end
    else
      :noop
    end
  end

  @spec clean() :: :ok
  def clean do
    Mix.Task.clear()
    :ok
  end

  # Private helpers

  defp get_config do
    case Mix.Project.config()[:dprint_markdown_formatter] do
      nil -> []
      config when is_list(config) -> config
      _invalid -> []
    end
  end

  defp get_format_attributes(config) do
    default_attributes = [
      moduledoc: true,
      doc: true,
      typedoc: true,
      shortdoc: true,
      deprecated: true
    ]

    case Keyword.get(config, :format_attributes) do
      nil -> default_attributes
      attrs when is_list(attrs) -> Keyword.merge(default_attributes, attrs)
      _invalid -> default_attributes
    end
  end

  defp get_source_files do
    Mix.Utils.extract_files(["lib"], [:ex])
  end

  defp check_if_formatting_needed(manifest, sources) do
    if manifest_outdated?(manifest, sources) do
      :ok
    else
      :noop
    end
  end

  defp manifest_outdated?(manifest, sources) do
    case File.stat(manifest) do
      {:error, _} ->
        true

      {:ok, manifest_stat} ->
        Enum.any?(sources, fn source ->
          case File.stat(source) do
            {:error, _} ->
              true

            {:ok, source_stat} ->
              source_stat.mtime > manifest_stat.mtime
          end
        end)
    end
  end

  defp format_sources(sources, format_attributes, config) do
    {dprint_opts, _} =
      Keyword.split(config, [
        :line_width,
        :text_wrap,
        :emphasis_kind,
        :strong_kind,
        :new_line_kind,
        :unordered_list_kind
      ])

    Enum.each(sources, fn source ->
      format_source_file(source, format_attributes, dprint_opts)
    end)
  end

  defp format_source_file(source, format_attributes, dprint_opts) do
    content = File.read!(source)

    case format_module_attributes(content, format_attributes, dprint_opts) do
      {:ok, formatted_content} when formatted_content != content ->
        File.write!(source, formatted_content)
        Mix.shell().info("Formatted #{source}")

      {:ok, _unchanged} ->
        :ok

      {:error, reason} ->
        Mix.shell().error("Failed to format #{source}: #{inspect(reason)}")
    end
  end

  defp format_module_attributes(content, format_attributes, dprint_opts) do
    case Sourceror.parse_string(content) do
      {:ok, ast} ->
        formatted_ast = transform_ast(ast, format_attributes, dprint_opts)
        formatted_content = Sourceror.to_string(formatted_ast)

        if formatted_content != content do
          IO.puts("DEBUG: Content was changed during formatting")
        else
          IO.puts("DEBUG: Content was NOT changed during formatting")
        end

        {:ok, formatted_content}

      {:error, error} ->
        IO.puts("DEBUG: Parse error: #{inspect(error)}")
        {:error, :parse_error}
    end
  rescue
    error ->
      IO.puts("DEBUG: Exception: #{inspect(error)}")
      {:error, error}
  end

  defp transform_ast(ast, format_attributes, dprint_opts) do
    Macro.prewalk(ast, fn node ->
      case node do
        # Debug: print @ nodes
        {:@, meta, args} ->
          IO.puts("DEBUG: Found @ node: #{inspect(node, limit: 1)}")

          case args do
            [{attr, attr_meta, [{:__block__, block_meta, [doc_content]}]}]
            when attr in [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated] and
                   is_binary(doc_content) ->
              IO.puts("DEBUG: Found heredoc #{attr}: #{String.slice(doc_content, 0, 50)}...")

              if format_attributes[attr] do
                case format_markdown_content(doc_content, dprint_opts) do
                  formatted when formatted != doc_content ->
                    IO.puts("DEBUG: Formatted #{attr}")
                    {:@, meta, [{attr, attr_meta, [{:__block__, block_meta, [formatted]}]}]}

                  _ ->
                    IO.puts("DEBUG: No change for #{attr}")
                    node
                end
              else
                IO.puts("DEBUG: Skipping #{attr} (disabled)")
                node
              end

            [{attr, attr_meta, [doc_content]}]
            when attr in [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated] and
                   is_binary(doc_content) ->
              IO.puts(
                "DEBUG: Found simple string #{attr}: #{String.slice(doc_content, 0, 50)}..."
              )

              if format_attributes[attr] do
                case format_markdown_content(doc_content, dprint_opts) do
                  formatted when formatted != doc_content ->
                    IO.puts("DEBUG: Formatted #{attr}")
                    {:@, meta, [{attr, attr_meta, [formatted]}]}

                  _ ->
                    IO.puts("DEBUG: No change for #{attr}")
                    node
                end
              else
                IO.puts("DEBUG: Skipping #{attr} (disabled)")
                node
              end

            _ ->
              IO.puts("DEBUG: Unknown @ pattern: #{inspect(args, limit: 1)}")
              node
          end

        _ ->
          node
      end
    end)
  end

  defp format_markdown_content(content, dprint_opts) do
    case DprintMarkdownFormatter.Native.format_markdown(content, dprint_opts) do
      {:ok, formatted} ->
        # Remove the trailing newline that dprint adds for consistency with heredoc usage
        String.trim_trailing(formatted, "\n")

      {:error, _reason} ->
        content
    end
  end

  defp manifest_path(opts) do
    build_path = Keyword.get(opts, :build_path, Mix.Project.build_path())
    app_name = Atom.to_string(Mix.Project.config()[:app])
    Path.join([build_path, "lib", app_name, @manifest])
  end

  defp write_manifest(manifest, sources) do
    File.mkdir_p!(Path.dirname(manifest))
    File.write!(manifest, :erlang.term_to_binary(sources))
  end
end
