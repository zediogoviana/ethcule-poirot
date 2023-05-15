FROM erlang:25

# elixir expects utf8.
ENV ELIXIR_VERSION="v1.14.0" \
  LANG=C.UTF-8

RUN set -xe \
  && ELIXIR_DOWNLOAD_URL="https://github.com/elixir-lang/elixir/archive/${ELIXIR_VERSION}.tar.gz" \
  && ELIXIR_DOWNLOAD_SHA256="ac129e266a1e04cdc389551843ec3dbdf36086bb2174d3d7e7936e820735003b" \
  && curl -fSL -o elixir-src.tar.gz $ELIXIR_DOWNLOAD_URL \
  && echo "$ELIXIR_DOWNLOAD_SHA256  elixir-src.tar.gz" | sha256sum -c - \
  && mkdir -p /usr/local/src/elixir \
  && tar -xzC /usr/local/src/elixir --strip-components=1 -f elixir-src.tar.gz \
  && rm elixir-src.tar.gz \
  && cd /usr/local/src/elixir \
  && make install clean \
  && find /usr/local/src/elixir/ -type f -not -regex "/usr/local/src/elixir/lib/[^\/]*/lib.*" -exec rm -rf {} + \
  && find /usr/local/src/elixir/ -type d -depth -empty -delete

COPY . /app

WORKDIR /app

ENV NEO4J_USER="neo4j"
ENV NEO4J_PASSWORD="test"
ENV DATABASE_URL="neo4j://core1"
ENV BLOCKSCOUT_API_URL="https://eth.blockscout.com/graphiql"
ENV DISSRUP_THE_GRAPH_API_URL="https://api.thegraph.com/subgraphs/name/dissrup-admin/mainnet-v12"

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get

CMD ["iex", "-S", "mix"]
