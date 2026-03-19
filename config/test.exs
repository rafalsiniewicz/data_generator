import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :data_generator, DataGenerator.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "data_generator_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :data_generator_web, DataGeneratorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "b50fNyOnWcaH4y289g8tbz1jKNYgCebOLEV6EQRb8aFFyRfazRKiLbK3+DSjwmzP",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :data_generator, DataGenerator.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

config :bcrypt_elixir, :log_rounds, 1

# Cloak vault key for test
config :data_generator, DataGenerator.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1", key: Base.decode64!("UE58DIkZ21oP743vIpaDW+WFiO6Ce0UWYfMzZPQze5Y=")}
  ]
