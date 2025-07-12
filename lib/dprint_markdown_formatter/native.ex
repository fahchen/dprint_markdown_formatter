defmodule DprintMarkdownFormatter.Native do
  @moduledoc """
  Native interface for dprint markdown formatting using Rustler.

  This module loads the Rust NIF that provides the actual formatting
  functionality.
  """

  mix_config = Mix.Project.config()
  github_url = mix_config[:package][:links]["GitHub"]
  version = mix_config[:version]

  use RustlerPrecompiled,
    otp_app: :dprint_markdown_formatter,
    crate: "dprint_markdown_formatter",
    base_url: "#{github_url}/releases/download/v#{version}",
    force_build:
      System.get_env("RUSTLER_PRECOMPILED_FORCE_BUILD") in ["1", "true"] or
        Mix.env() in [:dev, :test],
    version: version,
    nif_versions: ["2.16", "2.17"]

  @typep text_wrap_option() :: :always | :never | :maintain
  @typep emphasis_kind_option() :: :asterisks | :underscores
  @typep strong_kind_option() :: :asterisks | :underscores
  @typep new_line_kind_option() :: :auto | :lf | :crlf
  @typep unordered_list_kind_option() :: :dashes | :asterisks

  @typep format_options() :: %{
          line_width: pos_integer(),
          text_wrap: text_wrap_option(),
          emphasis_kind: emphasis_kind_option(),
          strong_kind: strong_kind_option(),
          new_line_kind: new_line_kind_option(),
          unordered_list_kind: unordered_list_kind_option()
        }

  @doc """
  Formats markdown text with configurable options.

  This function is implemented in Rust and provides the core formatting
  functionality using the dprint-plugin-markdown library.

  ## Parameters

  - `text` - The markdown text to format
  - `options` - A map of formatting options (see `format_options/0` type)

  ## Returns

  - `{:ok, formatted_text}` on successful formatting
  - `{:error, error_message}` if formatting fails

  ## Examples

      iex> options = %{line_width: 80, text_wrap: :always, emphasis_kind: :asterisks, strong_kind: :asterisks, new_line_kind: :auto, unordered_list_kind: :dashes}
      iex> DprintMarkdownFormatter.Native.format_markdown("# Hello    World", options)
      {:ok, "# Hello World\\n"}

      iex> DprintMarkdownFormatter.Native.format_markdown("*   Item 1\\n*   Item 2", options)
      {:ok, "- Item 1\\n- Item 2\\n"}
  """
  @spec format_markdown(String.t(), format_options()) :: {:ok, String.t()} | {:error, String.t()}
  def format_markdown(_text, _options), do: :erlang.nif_error(:nif_not_loaded)
end
