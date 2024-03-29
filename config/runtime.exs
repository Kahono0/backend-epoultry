import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/smart_farm start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :smart_farm, SmartFarmWeb.Endpoint, server: true
end

if config_env() == :prod do
  guardian_secret =
    System.get_env("GUARDIAN_SECRET") ||
      raise """
      environment variable GUARDIAN_SECRET is missing.
      You can generate one by calling: mix guardian.gen.secret
      """

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  at_api_key =
    System.get_env("AT_API_KEY") ||
      raise """
      environment variable AT_API_KEY is missing.
      """

  sms_shortcode =
    System.get_env("SMS_SHORTCODE") ||
      raise """
      environment variable SMS_SHORTCODE is missing.
      """

  at_username =
    System.get_env("AT_USERNAME") ||
      raise """
      environment variable AT_USERNAME is missing.
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []

  config :smart_farm, SmartFarm.Repo,
    ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :smart_farm, SmartFarmWeb.Endpoint,
    url: [scheme: "https", host: host, port: 443],
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :smart_farm, SmartFarm.Guardian,
    issuer: "smart_farm",
    secret_key: guardian_secret

  smart_farm_env =
    if env = System.get_env("SMART_FARM_ENV") do
      String.to_atom(env)
    else
      :prod
    end

  config :smart_farm,
    africastalking: [
      api_key: at_api_key,
      username: at_username,
      shortcode: sms_shortcode
    ],
    env: smart_farm_env

  config :waffle,
    storage: Waffle.Storage.Google.CloudStorage,
    bucket: System.fetch_env!("GCP_BUCKET")

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :smart_farm, SmartFarm.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
