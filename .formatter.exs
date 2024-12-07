[
  plugins: [
    Phoenix.LiveView.HTMLFormatter
  ],
  import_deps: [:phoenix],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"],
  migrate_eex_to_curly_interpolation: false
]
