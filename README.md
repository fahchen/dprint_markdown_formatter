# DprintMarkdownFormatter

A fast, configurable markdown formatter for Elixir that combines the power of
Rust's `dprint-plugin-markdown` with native Elixir integration. This library
provides high-performance markdown formatting with extensive configuration
options and seamless integration with `mix format`.

## Features

- **🚀 High Performance**: Uses Rust's `dprint-plugin-markdown` via Rustler NIFs
  for fast formatting
- **🔧 Highly Configurable**: Extensive formatting options for line width, text
  wrapping, emphasis styles, and more
- **📝 Module Attribute Formatting**: Automatically formats markdown in Elixir
  module attributes (`@moduledoc`, `@doc`, etc.)
- **🎯 Mix.Tasks.Format Integration**: Works seamlessly with `mix format` for
  markdown files
- **📄 Multiple Content Types**: Supports `.md`, `.markdown`, and Elixir source
  files (`.ex`, `.exs`)
- **🔤 Sigil Support**: Provides `~M` sigil for embedding markdown in Elixir
  code
- **📦 Precompiled Binaries**: Fast installation without requiring Rust
  toolchain

## Installation

Add `dprint_markdown_formatter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dprint_markdown_formatter, "~> 0.1.0"}
  ]
end
```

## Usage

### Using the ~M Sigil

```elixir
import DprintMarkdownFormatter.Sigil

markdown = ~M"""
# API Documentation

This is **bold** text with    extra   spaces.
"""
# Automatically formatted when imported
```

### Module Attribute Formatting

The formatter can automatically format markdown content in Elixir module
attributes:

```elixir
# Before formatting
@moduledoc """
This is   messy   markdown   content.

*   Poorly formatted list
*   Another    item
"""

# After formatting
@moduledoc """
This is messy markdown content.

- Properly formatted list
- Another item
"""
```

## Configuration & Integration

### Integration with mix format

Add to your `.formatter.exs`:

```elixir
[
  # ... other config
  plugins: [DprintMarkdownFormatter]
]
```

Now `mix format` will automatically format your markdown files and module
attributes!

### Global Configuration

Configure formatting options globally in your `mix.exs`:

```elixir
def project do
  [
    # ... other config
    dprint_markdown_formatter: [
      line_width: 100,
      text_wrap: "never",
      emphasis_kind: "underscores",
      format_module_attributes: true
    ]
  ]
end
```

### Available Options

| Option                      | Type    | Default       | Description                                        |
| --------------------------- | ------- | ------------- | -------------------------------------------------- |
| `:line_width`               | integer | `80`          | Maximum line width                                 |
| `:text_wrap`                | string  | `"always"`    | Text wrapping: `"always"`, `"never"`, `"maintain"` |
| `:emphasis_kind`            | string  | `"asterisks"` | Emphasis style: `"asterisks"`, `"underscores"`     |
| `:strong_kind`              | string  | `"asterisks"` | Strong text style: `"asterisks"`, `"underscores"`  |
| `:new_line_kind`            | string  | `"auto"`      | Line endings: `"auto"`, `"lf"`, `"crlf"`           |
| `:unordered_list_kind`      | string  | `"dashes"`    | List style: `"dashes"`, `"asterisks"`              |
| `:format_module_attributes` | various | `nil`         | Module attribute formatting (see below)            |

### Module Attribute Configuration

The `:format_module_attributes` option supports multiple input types for maximum
flexibility:

```elixir
# Skip formatting all module attributes (default)
format_module_attributes: nil

# Format common documentation attributes
format_module_attributes: true  # [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated]

# Format only specific attributes
format_module_attributes: [:moduledoc, :doc, :custom_doc, :note]
```

## Examples

### Basic Markdown Formatting

```elixir
markdown = """
#    Poorly   Formatted   Title

This is a paragraph with    extra   spaces.

*   Inconsistent list
*   Another    item
"""

formatted = DprintMarkdownFormatter.format(markdown, [])
# => "# Poorly Formatted Title\n\nThis is a paragraph with extra spaces.\n\n- Consistent list\n- Another item\n"
```

### Custom Configuration

```elixir
opts = [
  line_width: 120,
  text_wrap: "never",
  emphasis_kind: "underscores",
  unordered_list_kind: "asterisks"
]

DprintMarkdownFormatter.format(markdown, opts)
```

### Module Attribute Formatting

```elixir
# In your Elixir files, this:
defmodule MyModule do
  @moduledoc """
  This is   poorly   formatted   markdown.
  
  *   Bad list
  *   Another item
  """
  
  @doc """
  Function documentation with    extra   spaces.
  """
  def my_function, do: :ok
end

# Becomes this after running mix format:
defmodule MyModule do
  @moduledoc """
  This is poorly formatted markdown.
  
  - Bad list
  - Another item
  """
  
  @doc """
  Function documentation with extra spaces.
  """
  def my_function, do: :ok
end
```

## Development

### Prerequisites

- Elixir 1.14+
- Rust toolchain (optional, precompiled binaries available)

### Setup

```bash
# Get dependencies
mix deps.get

# Compile the project
mix compile

# Run tests
mix test

# Run quality checks
mix check  # Runs cargo fmt, cargo clippy, format, credo, and dialyzer
```

### Development Commands

```bash
# Elixir development
mix format         # Format Elixir code
mix credo         # Static analysis
mix dialyzer      # Type checking
mix test          # Run tests

# Rust development (in native/dprint_markdown_formatter/)
cargo build       # Build the NIF
cargo test        # Run Rust tests
cargo fmt         # Format Rust code
cargo clippy      # Lint Rust code
```

## Architecture

This is a hybrid Elixir/Rust project that bridges the gap between Elixir's
excellent developer experience and Rust's performance:

- **Elixir Layer**: Provides the public API, configuration management, and
  integration with Mix tooling
- **Rust NIF**: Handles the actual markdown formatting using
  `dprint-plugin-markdown`
- **Rustler**: Bridges Elixir and Rust with type-safe NIFs

### Key Components

- `DprintMarkdownFormatter`: Main public API
- `DprintMarkdownFormatter.Native`: Rustler NIF wrapper
- `DprintMarkdownFormatter.Sigil`: `~M` sigil implementation
- Rust NIF: Core formatting engine in `native/dprint_markdown_formatter/`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `mix check && mix test` to ensure all checks pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for
details.

## Acknowledgments

- Built on top of
  [dprint-plugin-markdown](https://github.com/dprint/dprint-plugin-markdown)
- Uses [Rustler](https://github.com/rusterlium/rustler) for Elixir/Rust
  integration
