defmodule DprintMarkdownFormatter.Native do
  @moduledoc """
  Native interface for dprint markdown formatting using Rustler.

  This module loads the Rust NIF that provides the actual formatting functionality.
  """

  use RustlerPrecompiled,
    otp_app: :dprint_markdown_formatter,
    crate: "dprint_markdown_formatter_nif",
    base_url: "https://github.com/fahchen/dprint_markdown_formatter/releases/download",
    force_build:
      System.get_env("RUSTLER_PRECOMPILED_FORCE_BUILD") in ["1", "true"] or
        Mix.env() in [:dev, :test],
    version: Mix.Project.config()[:version],
    nif_versions: ["2.16", "2.17"],
    targets: ~w(
      x86_64-unknown-linux-gnu
      x86_64-unknown-linux-musl
      aarch64-unknown-linux-gnu
      aarch64-unknown-linux-musl
      x86_64-apple-darwin
      aarch64-apple-darwin
      x86_64-pc-windows-msvc
      x86_64-pc-windows-gnu
    )

  @type text_wrap_option :: :always | :never | :maintain
  @type emphasis_kind_option :: :asterisks | :underscores
  @type strong_kind_option :: :asterisks | :underscores
  @type new_line_kind_option :: :auto | :lf | :crlf
  @type unordered_list_kind_option :: :dashes | :asterisks

  @type format_options :: [
          line_width: pos_integer(),
          text_wrap: text_wrap_option,
          emphasis_kind: emphasis_kind_option,
          strong_kind: strong_kind_option,
          new_line_kind: new_line_kind_option,
          unordered_list_kind: unordered_list_kind_option
        ]

  @doc """
  Formats markdown text with configurable options.

  This function is implemented in Rust and provides the core formatting functionality.
  """
  @spec format_markdown(String.t(), format_options) :: {:ok, String.t()} | {:error, String.t()}
  def format_markdown(_text, _options), do: :erlang.nif_error(:nif_not_loaded)
end
