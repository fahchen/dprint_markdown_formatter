# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Elixir Development
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project
- `mix test` - Run tests
- `mix format` - Format Elixir code
- `mix credo` - Run static analysis
- `mix dialyzer` - Run type checking
- `mix check` - Runs cargo fmt, cargo clippy, format, credo, and dialyzer (defined in mix.exs aliases)

### Rust Development
- `cd native/dprint_markdown_formatter_nif` - Navigate to Rust NIF directory
- `cargo build` - Build the Rust NIF
- `cargo test` - Run Rust tests
- `cargo fmt` - Format Rust code
- `cargo clippy` - Run Rust linter

### Pre-commit Workflow
- Run `mix check`, `mix test` before commit (mix check now includes cargo fmt and cargo clippy)

### Tool Preferences
- Always prefer `fd` over `find` for file searching
- Always prefer `rg` over `grep` for text searching

### Code Change Workflow
- After any Elixir code changes, always run `mix format`, `mix credo` and `mix dialyzer`
- After any Rust code changes, always run `cargo fmt` and `cargo clippy`
- After any code changes, run `mix test` (handles both Elixir and Rust testing)

## Architecture

This is a hybrid Elixir/Rust project that provides fast markdown formatting capabilities:

### Core Components
- **DprintMarkdownFormatter**: Main Elixir module providing the public API
- **DprintMarkdownFormatter.Native**: Rustler NIF wrapper for Rust functionality
- **DprintMarkdownFormatter.Sigil**: Provides ~M sigil for embedding markdown in Elixir code
- **Rust NIF**: Located in `native/dprint_markdown_formatter_nif/`, wraps dprint-plugin-markdown

### Key Design Patterns
- Uses Rustler to bridge Elixir and Rust for performance-critical markdown formatting
- Provides both functional API (`format/1`) and syntactic sugar (~M sigil)
- Rust NIF handles the actual markdown formatting using dprint-plugin-markdown
- Error handling wraps NIF errors in Elixir tuples

### File Structure
- `lib/` - Elixir source code
- `native/dprint_markdown_formatter_nif/` - Rust NIF implementation
- `test/` - Elixir tests
- `priv/native/` - Compiled NIF binaries