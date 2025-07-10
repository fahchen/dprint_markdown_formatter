# CLAUDE.md

Guide for Claude Code when working with this Elixir/Rust markdown formatter.

## Development Commands

### Essential Commands

- `mix check && mix test` - Run all quality checks and tests before committing
- `mix format` - Format Elixir code (run after any changes)
- `mix deps.get && mix compile` - Setup dependencies and compile

### Quality Checks

- `mix check` - Runs format, credo, dialyzer, cargo fmt, cargo clippy
- `mix credo` - Static analysis
- `mix dialyzer` - Type checking

### Rust NIF (in `native/dprint_markdown_formatter/`)

- `cargo build` - Build the NIF
- `cargo test` - Run Rust tests
- `cargo fmt && cargo clippy` - Format and lint Rust code

## Architecture

Fast markdown formatting via Rust NIF:

### Core Components

- **DprintMarkdownFormatter** - Main public API with Mix.exs config support
- **DprintMarkdownFormatter.Native** - Rustler NIF wrapper
- **DprintMarkdownFormatter.Sigil** - `~M` sigil for embedded markdown
- **Rust NIF** - `native/dprint_markdown_formatter/` wraps
  dprint-plugin-markdown

### Key Features

- High-performance Rust formatting via Rustler
- Module attribute formatting (`@moduledoc`, `@doc`, etc.)
- Mix format integration
- Configurable formatting options
- Precompiled binaries for fast installation

## Configuration

### Global Config (mix.exs)

```elixir
def project do
  [
    dprint_markdown_formatter: [
      line_width: 100,
      text_wrap: "never",
      emphasis_kind: "underscores",
      format_module_attributes: true  # Enable @moduledoc, @doc formatting
    ]
  ]
end
```

### Available Options

- `:line_width` - Max line width (default: 80)
- `:text_wrap` - "always", "never", "maintain" (default: "always")
- `:emphasis_kind` - "asterisks", "underscores" (default: "asterisks")
- `:strong_kind` - "asterisks", "underscores" (default: "asterisks")
- `:unordered_list_kind` - "dashes", "asterisks" (default: "dashes")
- `:format_module_attributes` - Configure attribute formatting:
  - `nil` (default) - Skip all formatting
  - `true` - Format `:moduledoc`, `:doc`, `:typedoc`, `:shortdoc`, `:deprecated`
  - `false` - Skip all formatting
  - `[:moduledoc, :doc, :custom]` - Format specific attributes only

## Code Standards

### Function Organization

1. **Maximize privacy** - Use `defp` for non-essential functions
2. **Order functions** - Public first, then private under "# Private helpers"
3. **Add type specs** - Include `@spec` for all public functions

### Type Organization

1. **Maximize privacy** - Use `@typep` for internal types
2. **Public types only** - Keep `@type` for types used by other modules
3. **Group related types** - Place type definitions near their usage

### Development Workflow

- Always run `mix format` after file changes
- Run `mix check` after Elixir changes
- Run `cargo fmt && cargo clippy` after Rust changes
- Test with `mix test` before committing

### Privacy Guidelines

Following recent improvements, the codebase maintains strict privacy boundaries:

- **13 internal types** are private (`@typep`) in Config, Native, and Validator modules
- **Internal validation functions** are private (`defp`) in Validator module
- **Public API surface** is minimal - only expose what other modules need
- **Cross-module dependencies** follow a clear hierarchy: Main → Config/Error/Validator/Native
