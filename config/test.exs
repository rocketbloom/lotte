import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :lotte, Lotte.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "lotte_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Wallaby browser-driven feature tests need a real server
config :lotte, LotteWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ExP7oi19a+YLY1B9V/qX/rJAae0L2z2C3CFC7wKIAjvDgqUreS70o9rSz7+Nc112",
  server: true

config :wallaby,
  otp_app: :lotte,
  base_url: "http://localhost:4002",
  driver: Wallaby.Chrome,
  screenshot_dir: "tmp/wallaby_screenshots",
  screenshot_on_failure: true,
  max_wait_time: String.to_integer(System.get_env("WALLABY_MAX_WAIT_TIME", "5000")),
  chromedriver: [
    headless: System.get_env("WALLABY_HEADLESS", "true") == "true"
  ]

if chrome_bin = System.get_env("CHROME_BIN") do
  config :wallaby, Wallaby.Chrome, binary: chrome_bin
end

# In test we don't send emails
config :lotte, Lotte.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
