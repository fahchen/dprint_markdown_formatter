# Used by "mix format"
[
  plugins: [DprintMarkdownFormatter],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib}/**/*.{ex,exs}",
    "test/mix/**/*.exs",
    "test/mix/tasks/compile/markdown_formatter_test.exs",
    "test/dprint_markdown_formatter_test.exs",
    "*.{md,markdown}",
    "{config,lib,test,priv}/**/*.{md,markdown}"
  ]
]
