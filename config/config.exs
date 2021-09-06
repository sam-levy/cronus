# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :sig,
  ecto_repos: [Sig.Repo]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :sig, Sig.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

config :sig_web,
  ecto_repos: [Sig.Repo],
  generators: [context_app: :sig, binary_id: true]

# Configures the endpoint
config :sig_web, SigWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "l64vxOgBKO85N2kT80nKMlV5oHxyn20Z8lMpn3JvBq1x4z0Len426OLzDrWAU/5Y",
  render_errors: [view: SigWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Sig.PubSub,
  live_view: [signing_salt: "sv2e1ui5"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../apps/sig_web/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
