defmodule DprintMarkdownFormatter.Validator do
  @moduledoc """
  Input validation utilities for DprintMarkdownFormatter.

  Provides comprehensive validation for all inputs including content, 
  options, and configuration values.
  """

  alias DprintMarkdownFormatter.Config
  alias DprintMarkdownFormatter.Error

  @typep validation_result(t) :: {:ok, t} | {:error, Error.ValidationError.t()}

  @doc """
  Validates content input for formatting.

  ## Examples

      iex> DprintMarkdownFormatter.Validator.validate_content("# Hello")
      {:ok, "# Hello"}

      iex> DprintMarkdownFormatter.Validator.validate_content("")
      {:ok, ""}

      iex> DprintMarkdownFormatter.Validator.validate_content(nil)
      {:error, %DprintMarkdownFormatter.Error.ValidationError{}}
  """
  @spec validate_content(term()) :: validation_result(String.t())
  def validate_content(content) when is_binary(content), do: {:ok, content}

  def validate_content(content) do
    {:error,
     Error.validation_error("Content must be a string",
       field: :content,
       value: content,
       expected: "string"
     )}
  end

  @doc """
  Validates formatting options.

  ## Examples

      iex> DprintMarkdownFormatter.Validator.validate_options([line_width: 80])
      {:ok, [line_width: 80]}

      iex> DprintMarkdownFormatter.Validator.validate_options(%{line_width: 80})
      {:error, %DprintMarkdownFormatter.Error.ValidationError{}}
  """
  @spec validate_options(term()) :: validation_result(keyword())
  def validate_options(opts) when is_list(opts) do
    case validate_option_values(opts) do
      {:ok, validated_opts} -> {:ok, validated_opts}
      {:error, _error} = error -> error
    end
  end

  def validate_options(opts) do
    {:error,
     Error.validation_error("Options must be a keyword list",
       field: :options,
       value: opts,
       expected: "keyword list"
     )}
  end

  @doc """
  Validates a configuration struct.

  ## Examples

      iex> config = %DprintMarkdownFormatter.Config{}
      iex> DprintMarkdownFormatter.Validator.validate_config(config)
      {:ok, config}
  """
  @spec validate_config(term()) :: validation_result(Config.t())
  def validate_config(%Config{} = config) do
    with {:ok, _line_width} <- validate_line_width(config.line_width),
         {:ok, _text_wrap} <- validate_text_wrap(config.text_wrap),
         {:ok, _emphasis_kind} <- validate_emphasis_kind(config.emphasis_kind),
         {:ok, _strong_kind} <- validate_strong_kind(config.strong_kind),
         {:ok, _new_line_kind} <- validate_new_line_kind(config.new_line_kind),
         {:ok, _unordered_list_kind} <- validate_unordered_list_kind(config.unordered_list_kind),
         {:ok, _format_module_attributes} <-
           validate_format_module_attributes(config.format_module_attributes) do
      {:ok, config}
    else
      {:error, _error} = error -> error
    end
  end

  def validate_config(config) do
    {:error,
     Error.validation_error("Invalid configuration type",
       field: :config,
       value: config,
       expected: "DprintMarkdownFormatter.Config struct"
     )}
  end

  # Private validation functions

  defp validate_extension(ext) when ext in [".md", ".markdown", ".ex", ".exs"], do: {:ok, ext}

  defp validate_extension(ext) when is_binary(ext) do
    {:error,
     Error.validation_error("Unsupported file extension",
       field: :extension,
       value: ext,
       expected: ".md, .markdown, .ex, or .exs"
     )}
  end

  defp validate_extension(ext) do
    {:error,
     Error.validation_error("Extension must be a string",
       field: :extension,
       value: ext,
       expected: "string"
     )}
  end

  defp validate_sigil(:M), do: {:ok, :M}

  defp validate_sigil(sigil) when is_atom(sigil) do
    {:error,
     Error.validation_error("Unsupported sigil",
       field: :sigil,
       value: sigil,
       expected: ":M"
     )}
  end

  defp validate_sigil(sigil) do
    {:error,
     Error.validation_error("Sigil must be an atom",
       field: :sigil,
       value: sigil,
       expected: "atom"
     )}
  end

  defp validate_option_values(opts) do
    result =
      Enum.reduce_while(opts, {:ok, []}, fn {key, value}, {:ok, acc} ->
        case validate_option_value(key, value) do
          {:ok, validated_value} -> {:cont, {:ok, [{key, validated_value} | acc]}}
          {:error, _error} = error -> {:halt, error}
        end
      end)

    case result do
      {:ok, validated_opts} -> {:ok, Enum.reverse(validated_opts)}
      {:error, _error} = error -> error
    end
  end

  defp validate_option_value(:line_width, value), do: validate_line_width(value)
  defp validate_option_value(:text_wrap, value), do: validate_text_wrap(value)
  defp validate_option_value(:emphasis_kind, value), do: validate_emphasis_kind(value)
  defp validate_option_value(:strong_kind, value), do: validate_strong_kind(value)
  defp validate_option_value(:new_line_kind, value), do: validate_new_line_kind(value)
  defp validate_option_value(:unordered_list_kind, value), do: validate_unordered_list_kind(value)
  defp validate_option_value(:extension, value), do: validate_extension(value)
  defp validate_option_value(:sigil, value), do: validate_sigil(value)

  defp validate_option_value(:format_module_attributes, value),
    do: validate_format_module_attributes(value)

  # Unknown options are allowed
  defp validate_option_value(_key, value), do: {:ok, value}

  defp validate_line_width(width) when is_integer(width) and width > 0 and width <= 1000,
    do: {:ok, width}

  defp validate_line_width(width) when is_integer(width) do
    {:error,
     Error.validation_error("Line width must be between 1 and 1000",
       field: :line_width,
       value: width,
       expected: "integer between 1 and 1000"
     )}
  end

  defp validate_line_width(width) do
    {:error,
     Error.validation_error("Line width must be an integer",
       field: :line_width,
       value: width,
       expected: "positive integer"
     )}
  end

  defp validate_text_wrap(wrap) when wrap in [:always, :never, :maintain], do: {:ok, wrap}

  defp validate_text_wrap(wrap) when is_atom(wrap) do
    {:error,
     Error.validation_error("Invalid text wrap option",
       field: :text_wrap,
       value: wrap,
       expected: ":always, :never, or :maintain"
     )}
  end

  defp validate_text_wrap(wrap) do
    {:error,
     Error.validation_error("Text wrap must be an atom",
       field: :text_wrap,
       value: wrap,
       expected: "atom"
     )}
  end

  defp validate_emphasis_kind(kind) when kind in [:asterisks, :underscores], do: {:ok, kind}

  defp validate_emphasis_kind(kind) when is_atom(kind) do
    {:error,
     Error.validation_error("Invalid emphasis kind",
       field: :emphasis_kind,
       value: kind,
       expected: ":asterisks or :underscores"
     )}
  end

  defp validate_emphasis_kind(kind) do
    {:error,
     Error.validation_error("Emphasis kind must be an atom",
       field: :emphasis_kind,
       value: kind,
       expected: "atom"
     )}
  end

  defp validate_strong_kind(kind) when kind in [:asterisks, :underscores], do: {:ok, kind}

  defp validate_strong_kind(kind) when is_atom(kind) do
    {:error,
     Error.validation_error("Invalid strong kind",
       field: :strong_kind,
       value: kind,
       expected: ":asterisks or :underscores"
     )}
  end

  defp validate_strong_kind(kind) do
    {:error,
     Error.validation_error("Strong kind must be an atom",
       field: :strong_kind,
       value: kind,
       expected: "atom"
     )}
  end

  defp validate_new_line_kind(kind) when kind in [:auto, :lf, :crlf], do: {:ok, kind}

  defp validate_new_line_kind(kind) when is_atom(kind) do
    {:error,
     Error.validation_error("Invalid new line kind",
       field: :new_line_kind,
       value: kind,
       expected: ":auto, :lf, or :crlf"
     )}
  end

  defp validate_new_line_kind(kind) do
    {:error,
     Error.validation_error("New line kind must be an atom",
       field: :new_line_kind,
       value: kind,
       expected: "atom"
     )}
  end

  defp validate_unordered_list_kind(kind) when kind in [:dashes, :asterisks], do: {:ok, kind}

  defp validate_unordered_list_kind(kind) when is_atom(kind) do
    {:error,
     Error.validation_error("Invalid unordered list kind",
       field: :unordered_list_kind,
       value: kind,
       expected: ":dashes or :asterisks"
     )}
  end

  defp validate_unordered_list_kind(kind) do
    {:error,
     Error.validation_error("Unordered list kind must be an atom",
       field: :unordered_list_kind,
       value: kind,
       expected: "atom"
     )}
  end

  defp validate_format_module_attributes(nil), do: {:ok, nil}
  defp validate_format_module_attributes(value) when is_boolean(value), do: {:ok, value}

  defp validate_format_module_attributes(attrs) when is_list(attrs) do
    if Enum.all?(attrs, &is_atom/1) do
      {:ok, attrs}
    else
      {:error,
       Error.validation_error("All module attributes must be atoms",
         field: :format_module_attributes,
         value: attrs,
         expected: "list of atoms"
       )}
    end
  end

  defp validate_format_module_attributes(value) do
    {:error,
     Error.validation_error("Format module attributes must be nil, boolean, or list of atoms",
       field: :format_module_attributes,
       value: value,
       expected: "nil, boolean, or list of atoms"
     )}
  end
end
