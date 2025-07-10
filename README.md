# DprintMarkdownFormatter

[![Hex.pm](https://img.shields.io/hexpm/v/dprint_markdown_formatter.svg)](https://hex.pm/packages/dprint_markdown_formatter)
[![Documentation](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/dprint_markdown_formatter/)

A fast, configurable markdown formatter for Elixir that combines the power of
Rust's `dprint-plugin-markdown` with native Elixir integration.

## Features

- **🚀 High Performance**: Uses Rust's `dprint-plugin-markdown` via Rustler NIFs
- **🔧 Highly Configurable**: Extensive formatting options for line width, text
  wrapping, emphasis styles, and more
- **📝 Module Attribute Formatting**: Automatically formats markdown in
  `@moduledoc`, `@doc`, etc.
- **🎯 Mix Integration**: Works seamlessly with `mix format`
- **🔤 Sigil Support**: Provides `~M` sigil for embedding markdown
- **📦 Precompiled Binaries**: Fast installation without requiring Rust
  toolchain

## Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:dprint_markdown_formatter, "~> 0.1.0"}
  ]
end
```

## Quick Start

### Basic Usage

```elixir
# Format a single string
markdown = """
#    Poorly   Formatted   Title

This is a paragraph with    extra   spaces.

*   Inconsistent list
*   Another    item
"""

formatted = DprintMarkdownFormatter.format(markdown, [])

# Output:
# # Poorly Formatted Title
# 
# This is a paragraph with extra spaces.
# 
# - Inconsistent list
# - Another item
```

### Sigil Usage

Use the `~M` sigil for embedding markdown content that gets automatically
formatted by `mix format`:

```elixir
import DprintMarkdownFormatter.Sigil

# This markdown will be automatically formatted when you run `mix format`
markdown = ~M"""
# API   Documentation   

This is **bold** text with    extra   spaces.

*   Poorly   formatted   list
"""

# After `mix format`, the sigil content becomes properly formatted
```

## Integration with mix format

Add to your `.formatter.exs`:

```elixir
[
  plugins: [DprintMarkdownFormatter]
]
```

This enables automatic formatting of `.md` and `.markdown` files. To also format
module attributes, configure `format_module_attributes` in your project.

## Configuration

### Global Configuration

Configure in your `mix.exs`:

```elixir
def project do
  [
    # ... other config
    dprint_markdown_formatter: [
      line_width: 100,
      text_wrap: :never,
      emphasis_kind: :underscores,
      format_module_attributes: true  # Enable module attribute formatting
    ]
  ]
end
```

### Per-call Configuration

```elixir
opts = [
  line_width: 120,
  text_wrap: :never,
  emphasis_kind: :underscores,
  unordered_list_kind: :asterisks
]

DprintMarkdownFormatter.format(markdown, opts)
```

### Available Options

| Option                      | Default      | Description                                     |
| --------------------------- | ------------ | ----------------------------------------------- |
| `:line_width`               | `80`         | Maximum line width                              |
| `:text_wrap`                | `:always`    | Text wrapping: `:always`, `:never`, `:maintain` |
| `:emphasis_kind`            | `:asterisks` | Emphasis style: `:asterisks`, `:underscores`    |
| `:strong_kind`              | `:asterisks` | Strong text style: `:asterisks`, `:underscores` |
| `:unordered_list_kind`      | `:dashes`    | List style: `:dashes`, `:asterisks`             |
| `:format_module_attributes` | `nil`        | Module attribute formatting (see below)         |

**Note:** Configuration values can be provided as atoms (`:never`) or strings
(`"never"`). Atoms are preferred for consistency with Elixir conventions.

### Module Attribute Configuration

```elixir
# Skip all formatting (default)
format_module_attributes: nil

# Format common doc attributes
format_module_attributes: true  # [:moduledoc, :doc, :typedoc, :shortdoc, :deprecated]

# Format specific attributes only
format_module_attributes: [:moduledoc, :doc, :custom_doc]
```

## Module Attribute Formatting Example

Before `mix format`:

```elixir
defmodule MyModule do
  @moduledoc """
  This is   messy   markdown   content.
  
  *   Poorly formatted list
  *   Another    item
  """
  
  @doc """
  Function documentation with    extra   spaces.
  """
  def my_function, do: :ok
end
```

After `mix format`:

```elixir
defmodule MyModule do
  @moduledoc """
  This is messy markdown content.
  
  - Properly formatted list
  - Another item
  """
  
  @doc """
  Function documentation with extra spaces.
  """
  def my_function, do: :ok
end
```

## Troubleshooting

### Module attributes not being formatted

Make sure you have:

1. Added `plugins: [DprintMarkdownFormatter]` to `.formatter.exs`
2. Configured `format_module_attributes: true` in your `mix.exs`
3. Run `mix format` on your `.ex` files

### Compilation issues

If you see Rust compilation errors, you can force using precompiled binaries:

```bash
export RUSTLER_PRECOMPILED_FORCE_BUILD=false
mix deps.get
```

## Development

### Prerequisites

- Elixir 1.16+
- Rust toolchain (optional, precompiled binaries available)

### Commands

```bash
# Setup
mix deps.get
mix compile

# Development
mix test              # Run tests
mix check            # Run all quality checks (format, credo, dialyzer, cargo fmt, cargo clippy)
mix format           # Format Elixir code
mix credo            # Static analysis
mix dialyzer         # Type checking

# Rust development (in native/dprint_markdown_formatter/)
cargo build          # Build the NIF
cargo test           # Run Rust tests
```

## Architecture

- **Elixir Layer**: Public API, configuration management, Mix integration
- **Rust NIF**: Core formatting engine using `dprint-plugin-markdown`
- **Rustler**: Type-safe bridge between Elixir and Rust

### Key Components

- `DprintMarkdownFormatter`: Main public API
- `DprintMarkdownFormatter.Native`: Rustler NIF wrapper
- `DprintMarkdownFormatter.Sigil`: `~M` sigil implementation

## License

MIT License - see the LICENSE file for details.

## Code Generation

This project was generated and developed with assistance from
[Claude Code](https://claude.ai/code), Anthropic's AI coding assistant. All
commits in this repository include co-author attribution to Claude.

## Acknowledgments

- Built on
  [dprint-plugin-markdown](https://github.com/dprint/dprint-plugin-markdown)
- Uses [Rustler](https://github.com/rusterlium/rustler) for Elixir/Rust
  integration
