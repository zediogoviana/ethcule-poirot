import Config

config :bolt_sips, Bolt,
  url: System.get_env("DATABASE_URL"),
  ssl: true,
  basic_auth: [username: System.get_env("NEO4J_USER"), password: System.get_env("NEO4J_PASSWORD")],
  pool_size: 200

config :ethcule_poirot,
  api_url: System.get_env("API_URL"),
  api_timeout: 120_000
