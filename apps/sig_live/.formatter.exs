[
  import_deps: [:phoenix],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}", "lib/**/*.{ex,sface}"],
  plugins: [Surface.Formatter.Plugin]
]
