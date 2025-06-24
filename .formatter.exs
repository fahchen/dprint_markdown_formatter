# Used by "mix format"
[
  plugins: [DprintMarkdownFormatter],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib}/**/*.{ex,exs}",
    "test/dprint_markdown_formatter_test.exs",
    "test/test_helper.exs",
    "*.{md,markdown}",
    "{config,lib,test,priv}/**/*.{md,markdown}"
  ]
]
