defmodule DprintMarkdownFormatter.Error do
  @moduledoc """
  Structured error types for DprintMarkdownFormatter.
  """

  @type t() ::
          parse_error()
          | format_error()
          | config_error()
          | nif_error()
          | validation_error()

  @type parse_error() :: %__MODULE__.ParseError{
          message: String.t(),
          line: non_neg_integer() | nil,
          column: non_neg_integer() | nil,
          context: String.t() | nil
        }

  @type format_error() :: %__MODULE__.FormatError{
          message: String.t(),
          original_error: term(),
          context: String.t() | nil
        }

  @type config_error() :: %__MODULE__.ConfigError{
          message: String.t(),
          key: atom() | nil,
          value: term() | nil
        }

  @type nif_error() :: %__MODULE__.NifError{
          message: String.t(),
          original_error: String.t() | nil
        }

  @type validation_error() :: %__MODULE__.ValidationError{
          message: String.t(),
          field: atom() | nil,
          value: term() | nil,
          expected: String.t() | nil
        }

  defmodule ParseError do
    @moduledoc """
    Error when parsing Elixir source code fails.
    """
    defexception [:message, :line, :column, :context]

    @impl Exception
    def exception(opts) do
      message = Keyword.get(opts, :message, "Parse error")
      line = Keyword.get(opts, :line)
      column = Keyword.get(opts, :column)
      context = Keyword.get(opts, :context)

      %__MODULE__{
        message: format_message(message, line, column, context),
        line: line,
        column: column,
        context: context
      }
    end

    defp format_message(message, nil, nil, nil), do: message
    defp format_message(message, line, nil, nil), do: "#{message} at line #{line}"

    defp format_message(message, line, column, nil),
      do: "#{message} at line #{line}, column #{column}"

    defp format_message(message, line, column, context),
      do: "#{message} at line #{line}, column #{column} in #{context}"
  end

  defmodule FormatError do
    @moduledoc """
    Error when formatting markdown content fails.
    """
    defexception [:message, :original_error, :context]

    @impl Exception
    def exception(opts) do
      message = Keyword.get(opts, :message, "Format error")
      original_error = Keyword.get(opts, :original_error)
      context = Keyword.get(opts, :context)

      formatted_message =
        case {original_error, context} do
          {nil, nil} -> message
          {error, nil} -> "#{message}: #{inspect(error)}"
          {nil, ctx} -> "#{message} in #{ctx}"
          {error, ctx} -> "#{message} in #{ctx}: #{inspect(error)}"
        end

      %__MODULE__{
        message: formatted_message,
        original_error: original_error,
        context: context
      }
    end
  end

  defmodule ConfigError do
    @moduledoc """
    Error when configuration is invalid.
    """
    defexception [:message, :key, :value]

    @impl Exception
    def exception(opts) do
      message = Keyword.get(opts, :message, "Configuration error")
      key = Keyword.get(opts, :key)
      value = Keyword.get(opts, :value)

      formatted_message =
        case {key, value} do
          {nil, nil} -> message
          {k, nil} -> "#{message} for key #{k}"
          {nil, v} -> "#{message} with value #{inspect(v)}"
          {k, v} -> "#{message} for key #{k} with value #{inspect(v)}"
        end

      %__MODULE__{
        message: formatted_message,
        key: key,
        value: value
      }
    end
  end

  defmodule NifError do
    @moduledoc """
    Error from the Rust NIF.
    """
    defexception [:message, :original_error]

    @impl Exception
    def exception(opts) do
      message = Keyword.get(opts, :message, "NIF error")
      original_error = Keyword.get(opts, :original_error)

      formatted_message =
        case original_error do
          nil -> message
          error -> "#{message}: #{error}"
        end

      %__MODULE__{
        message: formatted_message,
        original_error: original_error
      }
    end
  end

  defmodule ValidationError do
    @moduledoc """
    Error when input validation fails.
    """
    defexception [:message, :field, :value, :expected]

    @impl Exception
    def exception(opts) do
      message = Keyword.get(opts, :message, "Validation error")
      field = Keyword.get(opts, :field)
      value = Keyword.get(opts, :value)
      expected = Keyword.get(opts, :expected)

      formatted_message = build_message(message, field, value, expected)

      %__MODULE__{
        message: formatted_message,
        field: field,
        value: value,
        expected: expected
      }
    end

    defp build_message(message, nil, nil, nil), do: message
    defp build_message(message, field, nil, nil), do: "#{message} for field #{field}"

    defp build_message(message, field, value, nil),
      do: "#{message} for field #{field} with value #{inspect(value)}"

    defp build_message(message, field, value, expected),
      do: "#{message} for field #{field} with value #{inspect(value)}, expected #{expected}"
  end

  @doc """
  Creates a parse error.
  """
  @spec parse_error(String.t(), keyword()) :: parse_error()
  def parse_error(message, opts \\ []) do
    ParseError.exception(Keyword.put(opts, :message, message))
  end

  @doc """
  Creates a format error.
  """
  @spec format_error(String.t(), keyword()) :: format_error()
  def format_error(message, opts \\ []) do
    FormatError.exception(Keyword.put(opts, :message, message))
  end

  @doc """
  Creates a config error.
  """
  @spec config_error(String.t(), keyword()) :: config_error()
  def config_error(message, opts \\ []) do
    ConfigError.exception(Keyword.put(opts, :message, message))
  end

  @doc """
  Creates a NIF error.
  """
  @spec nif_error(String.t(), keyword()) :: nif_error()
  def nif_error(message, opts \\ []) do
    NifError.exception(Keyword.put(opts, :message, message))
  end

  @doc """
  Creates a validation error.
  """
  @spec validation_error(String.t(), keyword()) :: validation_error()
  def validation_error(message, opts \\ []) do
    ValidationError.exception(Keyword.put(opts, :message, message))
  end
end
