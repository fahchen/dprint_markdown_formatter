# Used by "mix format"
[
  plugins: [DprintMarkdownFormatter],
  import_deps: [:typed_structor],
  locals_without_parens: [
    custom_function: 1
  ],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib}/**/*.{ex,exs}",
    "test/mix/**/*.exs",
    "test/dprint_markdown_formatter_test.exs",
    "*.{md,markdown}",
    "{config,lib,test,priv}/**/*.{md,markdown}"
  ]
]
