---
description: "Bump the project version (patch, minor, or major) and stage the changes"
allowed-tools:
  - Read
  - Edit
  - Bash
---

You are helping to bump the version in this Elixir project.

Arguments provided: $ARGUMENTS

## Version Update Locations

Based on codebase analysis, these files need manual updates:

### Required Updates

1. **`mix.exs:4`** - `@version "0.3.0"` (primary version)
2. **`README.md:28`** - Installation example `{:dprint_markdown_formatter, "~> 0.1.0"}`
3. **`llms.txt:24`** - Installation example `{:dprint_markdown_formatter, "~> 0.1.0"}`

### Automatic Updates

- `mix.exs:10,82` - Use `@version` variable, update automatically
- GitHub workflows - Extract version from mix.exs automatically

### Optional/Independent

- `Cargo.toml:3` - Rust crate version (can be kept independent)

## Instructions

1. Read the current version from mix.exs (look for @version "x.x.x")
2. Parse the version type from arguments (patch, minor, major) - default to patch if not specified
3. Calculate the new version based on semantic versioning rules:
   - patch: increment the third number (x.x.X)
   - minor: increment the second number, reset patch to 0 (x.X.0)
   - major: increment the first number, reset minor and patch to 0 (X.0.0)
4. Update ALL required locations:
   - Update the @version line in mix.exs with the new version
   - Update installation examples in README.md and llms.txt (change version range appropriately)
5. Run `mix format` to ensure proper formatting
6. Stage the changed files with git
7. Create a commit with message "chore: bump version to X.X.X"

Be concise and show the version change clearly.

