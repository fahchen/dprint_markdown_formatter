defmodule DprintMarkdownFormatter.Error do
  @moduledoc """
  Error utilities for DprintMarkdownFormatter.

  This module provides validation errors and helper functions for creating
  standard Elixir exceptions with descriptive messages.
  """

  alias __MODULE__.ValidationError

  @type t() :: ValidationError.t()

  defmodule ValidationError do
    @moduledoc """
    Error when input validation fails.
    """
    use TypedStructor

    typed_structor definer: :defexception do
      field :field, atom()
      field :value, term()
      field :expected, String.t()
    end

    @impl Exception
    def exception(opts) do
      %__MODULE__{
        field: Keyword.get(opts, :field),
        value: Keyword.get(opts, :value),
        expected: Keyword.get(opts, :expected)
      }
    end

    @impl Exception
    def message(%__MODULE__{field: field, value: value, expected: expected}) do
      build_message("Validation error", field, value, expected)
    end

    defp build_message(message, nil, nil, nil), do: message
    defp build_message(message, field, nil, nil), do: "#{message} for field #{field}"

    defp build_message(message, field, value, nil),
      do: "#{message} for field #{field} with value #{inspect(value)}"

    defp build_message(message, field, value, expected),
      do: "#{message} for field #{field} with value #{inspect(value)}, expected #{expected}"
  end

  @doc """
  Creates a runtime error for parsing failures.

  Used when Elixir code parsing fails, such as when processing module attributes.

  ## Examples

      iex> DprintMarkdownFormatter.Error.parse_error("Failed to parse code")
      %RuntimeError{message: "Failed to parse code"}

      iex> original_error = %SyntaxError{message: "unexpected token"}
      iex> DprintMarkdownFormatter.Error.parse_error("Parse failed", original_error: original_error)
      %RuntimeError{message: "Parse failed: %SyntaxError{message: \\"unexpected token\\"}"}
  """
  @spec parse_error(String.t(), keyword()) :: Exception.t()
  def parse_error(message, opts \\ []) do
    case Keyword.get(opts, :original_error) do
      nil -> RuntimeError.exception(message: message)
      original -> RuntimeError.exception(message: "#{message}: #{inspect(original)}")
    end
  end

  @doc """
  Creates a runtime error for formatting failures.
  """
  @spec format_error(String.t(), keyword()) :: Exception.t()
  def format_error(message, opts \\ []) do
    case Keyword.get(opts, :original_error) do
      nil -> RuntimeError.exception(message: message)
      original -> RuntimeError.exception(message: "#{message}: #{inspect(original)}")
    end
  end

  @doc """
  Creates an argument error for configuration issues.
  """
  @spec config_error(String.t(), keyword()) :: Exception.t()
  def config_error(message, opts \\ []) do
    case Keyword.get(opts, :original_error) do
      nil -> ArgumentError.exception(message: message)
      original -> ArgumentError.exception(message: "#{message}: #{inspect(original)}")
    end
  end

  @doc """
  Creates a runtime error for NIF failures.

  Used when the Rust NIF returns an error during markdown formatting.

  ## Examples

      iex> DprintMarkdownFormatter.Error.nif_error("NIF formatting failed")
      %RuntimeError{message: "NIF formatting failed"}

      iex> DprintMarkdownFormatter.Error.nif_error("NIF error", original_error: "Invalid markdown syntax")
      %RuntimeError{message: "NIF error: Invalid markdown syntax"}
  """
  @spec nif_error(String.t(), keyword()) :: Exception.t()
  def nif_error(message, opts \\ []) do
    case Keyword.get(opts, :original_error) do
      nil -> RuntimeError.exception(message: message)
      original -> RuntimeError.exception(message: "#{message}: #{original}")
    end
  end

  @doc """
  Creates a validation error.
  """
  @spec validation_error(String.t(), keyword()) :: ValidationError.t()
  def validation_error(message, opts \\ []) do
    ValidationError.exception(Keyword.put(opts, :message, message))
  end
end
