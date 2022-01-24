[
  import_deps: [:phoenix],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}", "lib/**/*.{ex,sface}"],
  plugins: [Surface.Formatter.Plugin],
  locals_without_parens: [prop: 2, prop: 3, data: 2, data: 3, slot: 1, slot: 2]
]
