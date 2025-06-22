defmodule DprintMarkdownFormatter.Native do
  @moduledoc """
  Native interface for dprint markdown formatting using Rustler.

  This module loads the Rust NIF that provides the actual formatting functionality.
  """

  use Rustler, otp_app: :dprint_markdown_formatter, crate: "dprint_markdown_formatter_nif"

  @type text_wrap_option :: :always | :never | :maintain
  @type emphasis_kind_option :: :asterisks | :underscores
  @type strong_kind_option :: :asterisks | :underscores
  @type new_line_kind_option :: :auto | :lf | :crlf
  @type unordered_list_kind_option :: :dashes | :asterisks

  @type format_options :: [
          line_width: pos_integer(),
          text_wrap: text_wrap_option(),
          emphasis_kind: emphasis_kind_option(),
          strong_kind: strong_kind_option(),
          new_line_kind: new_line_kind_option(),
          unordered_list_kind: unordered_list_kind_option()
        ]

  @doc """
  Formats markdown text with configurable options.

  This function is implemented in Rust and provides the core formatting functionality.
  """
  @spec format_markdown(String.t(), format_options()) :: {:ok, String.t()} | {:error, String.t()}
  def format_markdown(_text, _options), do: :erlang.nif_error(:nif_not_loaded)
end
