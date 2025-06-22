defmodule DprintMarkdownFormatter.Native do
  @moduledoc """
  Native interface for dprint markdown formatting using Rustler.

  This module loads the Rust NIF that provides the actual formatting functionality.
  """

  use Rustler, otp_app: :dprint_markdown_formatter, crate: "dprint_markdown_formatter_nif"

  @doc """
  Formats markdown text using default configuration.

  This function is implemented in Rust and provides the core formatting functionality.
  """
  @spec format_markdown(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def format_markdown(_text), do: :erlang.nif_error(:nif_not_loaded)
end
