defmodule DprintMarkdownFormatter.Config do
  @moduledoc """
  Configuration management for DprintMarkdownFormatter with proper type safety and
  validation.
  """
  use TypedStructor

  @typep text_wrap_option() :: :always | :never | :maintain
  @typep emphasis_kind_option() :: :asterisks | :underscores
  @typep strong_kind_option() :: :asterisks | :underscores
  @typep new_line_kind_option() :: :auto | :lf | :crlf
  @typep unordered_list_kind_option() :: :dashes | :asterisks
  @typep module_attributes_option() :: nil | boolean() | [atom()]

  typed_structor enforce: true do
    field :line_width, pos_integer(), default: 80
    field :text_wrap, text_wrap_option(), default: :always
    field :emphasis_kind, emphasis_kind_option(), default: :asterisks
    field :strong_kind, strong_kind_option(), default: :asterisks
    field :new_line_kind, new_line_kind_option(), default: :auto
    field :unordered_list_kind, unordered_list_kind_option(), default: :dashes
    field :format_module_attributes, module_attributes_option(), default: nil
  end

  @doc """
  Returns the default configuration.

  ## Examples

      iex> DprintMarkdownFormatter.Config.default()
      %DprintMarkdownFormatter.Config{
        line_width: 80,
        text_wrap: :always,
        emphasis_kind: :asterisks,
        strong_kind: :asterisks,
        new_line_kind: :auto,
        unordered_list_kind: :dashes,
        format_module_attributes: nil
      }
  """
  @spec default() :: t()
  def default, do: %__MODULE__{}

  @doc """
  Returns the default list of module attributes that are formatted when
  `format_module_attributes: true`.
  """
  @spec default_doc_attributes() :: [atom()]
  def default_doc_attributes do
    [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated]
  end

  @doc """
  Loads and validates configuration from Mix.Project.config().

  Returns a validated configuration struct with proper type checking. Invalid
  values are replaced with defaults and warnings are logged.

  ## Examples

      # With valid configuration in mix.exs
      iex> DprintMarkdownFormatter.Config.load()
      %DprintMarkdownFormatter.Config{line_width: 80, text_wrap: :always}

      # With invalid configuration values (logs warnings and uses defaults)
      iex> DprintMarkdownFormatter.Config.load()
      %DprintMarkdownFormatter.Config{line_width: 80, text_wrap: :always}
  """
  @spec load() :: t()
  def load do
    project_config = Mix.Project.config()
    raw_config = Keyword.get(project_config, :dprint_markdown_formatter, [])

    from_keyword(raw_config)
  end

  @doc """
  Creates a configuration struct from a keyword list with validation.

  ## Examples

      iex> DprintMarkdownFormatter.Config.from_keyword([line_width: 100])
      %DprintMarkdownFormatter.Config{line_width: 100}

      iex> DprintMarkdownFormatter.Config.from_keyword([text_wrap: :never])
      %DprintMarkdownFormatter.Config{text_wrap: :never}

      iex> DprintMarkdownFormatter.Config.from_keyword([format_module_attributes: true])
      %DprintMarkdownFormatter.Config{format_module_attributes: true}
  """
  @spec from_keyword(keyword()) :: t()
  def from_keyword(opts) when is_list(opts) do
    config = default()

    Enum.reduce(opts, config, fn {key, value}, acc ->
      case validate_option(key, value) do
        {:ok, validated_value} ->
          Map.put(acc, key, validated_value)

        {:error, reason} ->
          require Logger
          Logger.warning("Invalid configuration for #{key}: #{reason}. Using default value.")
          acc
      end
    end)
  end

  @doc """
  Merges a configuration struct with runtime options.

  Runtime options take precedence over configuration values. Only valid options
  are merged; invalid options are ignored with a warning.

  ## Examples

      iex> config = %DprintMarkdownFormatter.Config{line_width: 80}
      iex> DprintMarkdownFormatter.Config.merge(config, [line_width: 100])
      %DprintMarkdownFormatter.Config{line_width: 100}

      iex> config = %DprintMarkdownFormatter.Config{text_wrap: :always}
      iex> DprintMarkdownFormatter.Config.merge(config, [text_wrap: :never, line_width: 120])
      %DprintMarkdownFormatter.Config{text_wrap: :never, line_width: 120}
  """
  @spec merge(t(), keyword()) :: t()
  def merge(%__MODULE__{} = config, opts) when is_list(opts) do
    # Only merge keys that are actually specified in the options
    Enum.reduce(opts, config, fn {key, value}, acc ->
      case validate_option(key, value) do
        {:ok, validated_value} ->
          Map.put(acc, key, validated_value)

        {:error, reason} ->
          require Logger
          Logger.warning("Invalid configuration for #{key}: #{reason}. Using existing value.")
          acc
      end
    end)
  end

  @doc """
  Returns a map with only the dprint-related fields for the NIF.

  Excludes format_module_attributes which is only used by Elixir code. This map is
  passed directly to the Rust NIF for formatting.

  ## Examples

      iex> config = %DprintMarkdownFormatter.Config{line_width: 100, text_wrap: :never}
      iex> DprintMarkdownFormatter.Config.to_nif_config(config)
      %{line_width: 100, text_wrap: :never, emphasis_kind: :asterisks}
  """
  @spec to_nif_config(t()) :: %{
          line_width: non_neg_integer(),
          text_wrap: atom(),
          emphasis_kind: atom(),
          strong_kind: atom(),
          new_line_kind: atom(),
          unordered_list_kind: atom()
        }
  def to_nif_config(%__MODULE__{} = config) do
    %{
      line_width: config.line_width,
      text_wrap: config.text_wrap,
      emphasis_kind: config.emphasis_kind,
      strong_kind: config.strong_kind,
      new_line_kind: config.new_line_kind,
      unordered_list_kind: config.unordered_list_kind
    }
  end

  @doc """
  Resolves module attributes configuration to a list of atoms.

  ## Examples

      iex> config = %DprintMarkdownFormatter.Config{format_module_attributes: true}
      iex> DprintMarkdownFormatter.Config.resolve_module_attributes(config)
      [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated]

      iex> config = %DprintMarkdownFormatter.Config{format_module_attributes: [:custom]}
      iex> DprintMarkdownFormatter.Config.resolve_module_attributes(config)
      [:custom]

      iex> config = %DprintMarkdownFormatter.Config{format_module_attributes: nil}
      iex> DprintMarkdownFormatter.Config.resolve_module_attributes(config)
      []
  """
  @spec resolve_module_attributes(t()) :: [atom()]
  def resolve_module_attributes(%__MODULE__{format_module_attributes: nil}), do: []
  def resolve_module_attributes(%__MODULE__{format_module_attributes: false}), do: []

  def resolve_module_attributes(%__MODULE__{format_module_attributes: true}),
    do: default_doc_attributes()

  def resolve_module_attributes(%__MODULE__{format_module_attributes: attrs}) when is_list(attrs),
    do: attrs

  # Private helpers

  defp validate_option(:line_width, value) when is_integer(value) and value > 0, do: {:ok, value}

  defp validate_option(:line_width, value),
    do: {:error, "must be a positive integer, got: #{inspect(value)}"}

  defp validate_option(:text_wrap, value) when value in [:always, :never, :maintain],
    do: {:ok, value}

  defp validate_option(:text_wrap, value) when is_binary(value) do
    case value do
      "always" -> {:ok, :always}
      "never" -> {:ok, :never}
      "maintain" -> {:ok, :maintain}
      _invalid_value -> {:error, "must be :always, :never, or :maintain, got: #{inspect(value)}"}
    end
  end

  defp validate_option(:text_wrap, value),
    do: {:error, "must be :always, :never, or :maintain, got: #{inspect(value)}"}

  defp validate_option(:emphasis_kind, value) when value in [:asterisks, :underscores],
    do: {:ok, value}

  defp validate_option(:emphasis_kind, value) when is_binary(value) do
    case value do
      "asterisks" -> {:ok, :asterisks}
      "underscores" -> {:ok, :underscores}
      _invalid_value -> {:error, "must be :asterisks or :underscores, got: #{inspect(value)}"}
    end
  end

  defp validate_option(:emphasis_kind, value),
    do: {:error, "must be :asterisks or :underscores, got: #{inspect(value)}"}

  defp validate_option(:strong_kind, value) when value in [:asterisks, :underscores],
    do: {:ok, value}

  defp validate_option(:strong_kind, value) when is_binary(value) do
    case value do
      "asterisks" -> {:ok, :asterisks}
      "underscores" -> {:ok, :underscores}
      _invalid_value -> {:error, "must be :asterisks or :underscores, got: #{inspect(value)}"}
    end
  end

  defp validate_option(:strong_kind, value),
    do: {:error, "must be :asterisks or :underscores, got: #{inspect(value)}"}

  defp validate_option(:new_line_kind, value) when value in [:auto, :lf, :crlf], do: {:ok, value}

  defp validate_option(:new_line_kind, value) when is_binary(value) do
    case value do
      "auto" -> {:ok, :auto}
      "lf" -> {:ok, :lf}
      "crlf" -> {:ok, :crlf}
      _invalid_value -> {:error, "must be :auto, :lf, or :crlf, got: #{inspect(value)}"}
    end
  end

  defp validate_option(:new_line_kind, value),
    do: {:error, "must be :auto, :lf, or :crlf, got: #{inspect(value)}"}

  defp validate_option(:unordered_list_kind, value) when value in [:dashes, :asterisks],
    do: {:ok, value}

  defp validate_option(:unordered_list_kind, value) when is_binary(value) do
    case value do
      "dashes" -> {:ok, :dashes}
      "asterisks" -> {:ok, :asterisks}
      _invalid_value -> {:error, "must be :dashes or :asterisks, got: #{inspect(value)}"}
    end
  end

  defp validate_option(:unordered_list_kind, value),
    do: {:error, "must be :dashes or :asterisks, got: #{inspect(value)}"}

  defp validate_option(:format_module_attributes, nil), do: {:ok, nil}
  defp validate_option(:format_module_attributes, value) when is_boolean(value), do: {:ok, value}

  defp validate_option(:format_module_attributes, value) when is_list(value) do
    if Enum.all?(value, &is_atom/1) do
      {:ok, value}
    else
      {:error, "must be a list of atoms, got: #{inspect(value)}"}
    end
  end

  defp validate_option(:format_module_attributes, value),
    do: {:error, "must be nil, boolean, or list of atoms, got: #{inspect(value)}"}

  defp validate_option(key, value),
    do: {:error, "unknown configuration option #{key} with value #{inspect(value)}"}
end
