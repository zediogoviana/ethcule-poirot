import Config

config :bolt_sips, Bolt,
  url: System.get_env("DATABASE_URL"),
  ssl: String.match?(System.get_env("DATABASE_URL", ""), ~r/^neo4j\+s:\/\/.*/),
  ssl_options: [verify: :verify_none],
  basic_auth: [username: System.get_env("NEO4J_USER"), password: System.get_env("NEO4J_PASSWORD")],
  pool_size: 200

config :ethcule_poirot,
  default_api_adapter: Adapters.Api.Blockscout,
  pool_size: 10

config :ethcule_poirot, Adapters.Api.Blockscout,
  api_url: System.get_env("BLOCKSCOUT_API_URL"),
  api_timeout: 120_000

config :ethcule_poirot, Adapters.Api.DissrupTheGraph,
  api_url: System.get_env("DISSRUP_THE_GRAPH_API_URL"),
  api_timeout: 120_000
