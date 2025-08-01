defmodule DprintMarkdownFormatter.Validator do
  @moduledoc """
  Input validation utilities for DprintMarkdownFormatter.

  Provides comprehensive validation for all inputs including content, options, and
  configuration values.
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

  Ensures that options are provided as a keyword list and all values are valid.
  Unknown options are allowed for forward compatibility.

  ## Examples

      iex> DprintMarkdownFormatter.Validator.validate_options([line_width: 80])
      {:ok, [line_width: 80]}

      iex> DprintMarkdownFormatter.Validator.validate_options([line_width: 80, text_wrap: :never])
      {:ok, [line_width: 80, text_wrap: :never]}

      iex> DprintMarkdownFormatter.Validator.validate_options(%{line_width: 80})
      {:error, %DprintMarkdownFormatter.Error.ValidationError{}}

      iex> DprintMarkdownFormatter.Validator.validate_options([line_width: -1])
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

  defp validate_extension(value),
    do: validate_string_choice(value, :extension, [".md", ".markdown", ".ex", ".exs"])

  defp validate_sigil(value), do: validate_atom_choice(value, :sigil, [:M])

  defp validate_string_choice(value, field, valid_choices) when is_binary(value) do
    if value in valid_choices do
      {:ok, value}
    else
      expected_string = Enum.join(valid_choices, ", ")

      {:error,
       Error.validation_error(
         "Unsupported #{field |> Atom.to_string() |> String.replace("_", " ")}",
         field: field,
         value: value,
         expected: expected_string
       )}
    end
  end

  defp validate_string_choice(value, field, _valid_choices) do
    {:error,
     Error.validation_error(
       "#{field |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()} must be a string",
       field: field,
       value: value,
       expected: "string"
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

  defp validate_text_wrap(value),
    do: validate_atom_choice(value, :text_wrap, [:always, :never, :maintain])

  defp validate_emphasis_kind(value),
    do: validate_atom_choice(value, :emphasis_kind, [:asterisks, :underscores])

  defp validate_strong_kind(value),
    do: validate_atom_choice(value, :strong_kind, [:asterisks, :underscores])

  defp validate_new_line_kind(value),
    do: validate_atom_choice(value, :new_line_kind, [:auto, :lf, :crlf])

  defp validate_unordered_list_kind(value),
    do: validate_atom_choice(value, :unordered_list_kind, [:dashes, :asterisks])

  defp validate_atom_choice(value, field, valid_choices) when is_atom(value) do
    if value in valid_choices do
      {:ok, value}
    else
      expected_string = Enum.map_join(valid_choices, ", ", &inspect/1)

      {:error,
       Error.validation_error("Invalid #{field |> Atom.to_string() |> String.replace("_", " ")}",
         field: field,
         value: value,
         expected: expected_string
       )}
    end
  end

  defp validate_atom_choice(value, field, _valid_choices) do
    {:error,
     Error.validation_error(
       "#{field |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()} must be an atom",
       field: field,
       value: value,
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
