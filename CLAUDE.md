# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Development Commands

### Elixir Development

- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project
- `mix test` - Run tests
- `mix format` - Format Elixir code
- `mix credo` - Run static analysis
- `mix dialyzer` - Run type checking
- `mix check` - Runs cargo fmt, cargo clippy, format, credo, and dialyzer
  (defined in mix.exs aliases)

### Rust Development

- `cd native/dprint_markdown_formatter_nif` - Navigate to Rust NIF directory
- `cargo build` - Build the Rust NIF
- `cargo test` - Run Rust tests
- `cargo fmt` - Format Rust code
- `cargo clippy` - Run Rust linter

### Pre-commit Workflow

- Run `mix check && mix test` before commit to verify all checks pass
- `mix check` includes: cargo fmt, cargo clippy, format, credo, and dialyzer
- Always verify both quality checks and tests before committing

### Tool Preferences

- Always prefer `fd` over `find` for file searching
- Always prefer `rg` over `grep` for text searching
- Use `sourceror` for AST manipulation and transformation of Elixir code
  - Sourceror provides robust parsing and code generation capabilities
  - Documentation: https://hexdocs.pm/sourceror/readme.html
  - Zipper API for AST traversal: https://hexdocs.pm/sourceror/zippers.html
  - Main module docs: https://hexdocs.pm/sourceror/Sourceror.html
  - Examples: https://hexdocs.pm/sourceror/expand_multi_alias.html

### Code Change Workflow

- **IMPORTANT**: Always run `mix format` immediately after making any file
  changes
- After any Elixir code changes, always run `mix format`, `mix credo` and
  `mix dialyzer`
- After any Rust code changes, always run `cargo fmt` and `cargo clippy`
- After any code changes, run `mix test` (handles both Elixir and Rust testing)

### Precompiled Binaries

- Uses `rustler_precompiled` for faster installs without requiring Rust
  toolchain
- Set `RUSTLER_PRECOMPILED_FORCE_BUILD=true` to force compilation from source
- Release workflow automatically builds binaries for multiple platforms

## Architecture

This is a hybrid Elixir/Rust project that provides fast markdown formatting
capabilities:

### Core Components

- **DprintMarkdownFormatter**: Main Elixir module providing the public API with
  Mix.exs configuration support
- **DprintMarkdownFormatter.Native**: Rustler NIF wrapper for Rust functionality
  with detailed type specifications
- **DprintMarkdownFormatter.Sigil**: Provides ~M sigil for embedding markdown in
  Elixir code
- **Rust NIF**: Located in `native/dprint_markdown_formatter_nif/`, wraps
  dprint-plugin-markdown with configurable options

### Key Design Patterns

- Uses Rustler to bridge Elixir and Rust for performance-critical markdown
  formatting
- Provides both functional API (`format/2`) and syntactic sugar (~M sigil)
- Rust NIF handles the actual markdown formatting using dprint-plugin-markdown
- Error handling wraps NIF errors in Elixir tuples
- Configuration can be set globally in `mix.exs` and overridden per call
- Implements Mix.Tasks.Format behavior for integration with `mix format`

### File Structure

- `lib/` - Elixir source code
- `native/dprint_markdown_formatter_nif/` - Rust NIF implementation
- `test/` - Elixir tests
- `priv/native/` - Compiled NIF binaries

### Dependencies

- **Rustler**: 0.36.2 (latest) - Elixir/Rust NIF bridge
- **dprint-plugin-markdown**: 0.18.0 (latest) - Core markdown formatting
- **dprint-core**: 0.67.4 - Core dprint functionality

### Configuration

Global formatting options can be configured in `mix.exs`:

```elixir
def project do
  [
    # ... other config
    dprint_markdown_formatter: [
      line_width: 100,
      text_wrap: "never",
      emphasis_kind: "underscores",
      
      # Enable formatting for default attributes (moduledoc, doc, typedoc, shortdoc, deprecated)
      format_module_attributes: true,
      
      # Or disable all formatting (default behavior)
      # format_module_attributes: nil,
      
      # Or specify custom attributes
      # format_module_attributes: [:moduledoc, :doc, :custom_doc, :note]
    ]
  ]
end
```

Available options:

- `:line_width` - Maximum line width (default: 80)
- `:text_wrap` - "always", "never", "maintain" (default: "always")
- `:emphasis_kind` - "asterisks", "underscores" (default: "asterisks")
- `:strong_kind` - "asterisks", "underscores" (default: "asterisks")
- `:new_line_kind` - "auto", "lf", "crlf" (default: "auto")
- `:unordered_list_kind` - "dashes", "asterisks" (default: "dashes")
- `:format_module_attributes` - Configure which module attributes to format.
  Supports four input types for maximum flexibility:

  **`nil` (default):** Skip formatting all module attributes.

  **Boolean `true`:** Format common documentation attributes: `:moduledoc`,
  `:doc`, `:typedoc`, `:shortdoc`, `:deprecated`

  **Boolean `false`:** Skip formatting all module attributes.

  **List of atoms:** Format only the specified attributes. Any module attribute
  containing string content can be specified. Examples:

      # Format only module docs
      format_module_attributes: [:moduledoc]

      # Format standard docs plus custom attributes  
      format_module_attributes: [:moduledoc, :doc, :custom_doc, :note, :example]

      # Format testing attributes
      format_module_attributes: [:moduletag, :tag, :describetag]

  Only string values are processed (boolean `false` values are preserved
  unchanged). Use `default_doc_attributes/0` to get the standard list.

## Code Standards & Conventions

### Function Organization and Visibility

1. **Maximize function privacy**: Make functions private (`defp`) wherever
   possible, keeping only essential functions in the public API. This improves
   encapsulation and reduces the module's public surface area.

2. **Proper function organization**: Always place public functions first,
   followed by private functions under a "# Private helpers" comment section.
   This follows standard Elixir conventions for better code readability.

3. **Add type specifications**: Include `@spec` for all public functions to
   improve code documentation, enable better tooling support, and catch
   type-related issues early.
