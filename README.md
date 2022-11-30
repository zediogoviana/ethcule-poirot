# Ethcule Poirot

<img src="images/ethcule-poirot.jpg" width="100" />

Application to explore Ethereum transactions using any API and a Neo4j database to store nodes (accounts/smart contracts) and respective relationships, through a transaction.

The goal of this project is to start by exploring a specific Address, and then redo the same process for other Addresses of interest, and that correlate in some way with an existing one. This way, we're able to grow our Network in the direction we want to.

<p align="center">
  <img src="images/network-example.png" width="500" />
</p>

Recently, also added support for [ENS](https://ens.domains/), which means that addresses that have a name associated, will also have a `name` field in the respective node. This helps with visualization and identification of nodes when exploring the network.

### Neo4j Database

To store information we're using [Neo4j](https://neo4j.com/). It's a graph data platform, and that's exactly the structure we want to represent a network of Ethereum Addresses.

Neo4j can be installed locally, through several ways, and in this project we're using their Docker image.

There's also the possibility of using a cloud service called [Neo4j AuraDB](https://neo4j.com/cloud/platform/aura-graph-database/?ref=get-started-dropdown-cta). They offer a free version with a limit of 50k nodes and 175k relationships if you want to run a fully managed database.


## Project Structure
Looking at the image below, there's a clear structure for the supervision tree of this project. On one side we have Processes related to the Database interaction, and on the other we have processes that take care of the exploration of each address.

- `Neo4j.Client`: is a GenServer that holds the `conn` in the state and exposes the respective API to exexute queries in the DB.
- `EthculePoirot.NetworkExplorer`: is a GenServer that holds the Set of visited nodes, the ones that are being explored by `EthculePoirot.AddressExplorer` and other info required to manage the exploration step. It also manages the number of Addresses being explored at the same time, through a `pool_size` configuration.

![supervision tree](images/supervision-tree.png)

## API Adapters

It's possible to use different APIs to index and build the desired network. For example, we can use an API that provides the Blockchain transaction history to map interactions between addresses, but we can also use an API like a [Subgraph](https://thegraph.com/hosted-service/) and build a network of interactions between an Address and one/several SmartContract(s).

### Existing
 - [Blockscout](https://blockscout.com/eth/mainnet/graphiql): It's free to use and it returns transactions and addresses already organized with a lot of information that we need to build our own network. 
   The downside of using it is rate limits from Cloudflare, and a low complexity GraphQL query, that only enables us to query 22 transactions at a time (with the current information we are requesting).
 - [Dissrup TheGraph NFT sales](https://thegraph.com/hosted-service/subgraph/dissrup-admin/mainnet-v12): Dissrup is a NFT marketplace, and using TheGraph's API it's possible to inspect NFT Sales. This is a proof of concept that the project doesn't need to explore only Ethereum transactions.

 
### How to implement new ones

Just create a new file under `lib/adapters/api` and implement the respective behaviour.

```elixir
defmodule Adapters.Api.NewApi do
  @behaviour Behaviours.Api

  @impl true
  def initial_setup, do: # code

  @impl true
  def transactions_for_address(address), do: # code
  
  @impl true
  def address_information(address), do: # code
end
```

## Setup, lint, and tests


```bash
# To setup Elixir locally without setting up a Neo4j DB
# After, you need to update the `.envrc` with the correct variables.
bin/setup

# or to setup everything inside Docker
# to use Neo4j with Docker, comment out `:ssl` option in the `config/config.exs` file
bin/setup_docker
``` 

There are the following scripts available, also:

```bash
bin/lint
bin/test
```

## How to Run

```bash
# To run locally with a custom Neo4j DB
bin/server

# or to run everything inside Docker
bin/server_docker
``` 

This will start the application and the respective Supervisors for the Explorers and Neo4j interactions.

After the app starts, to start exploring just pass in an address, and an exploration depth to ` EthculePoirot.NetworkExplorer.explore/2`. (It's advised to use a depth of 3)

```elixir
# using the Blockscout API as default
address = "0xSomeAddress"
depth = 2
EthculePoirot.NetworkExplorer.explore(address, depth)

# using a specific implemented API
address = "0xSomeAddress"
depth = 2
EthculePoirot.NetworkExplorer.explore(address, depth, Adapters.Api.DissrupTheGraph)
```

Each step will be printed, and the exploration for the given address is completed when the following line appears `Fully explored 0xSomeAddress`.

After this, you can check the Neo4j database and play around with it (using `Neo4j Bloom`, for example). Assuming you want to explore more addresses of interest, you just redo the process above with a new address `address = 0xSomeAddress2`, and a new cluster will be created or appended to the existing one. This way, it's possible to follow through and explore the path you wish to.

It's also possible to clear the database to delete all nodes and relationships, to start explorating from scratch.

```elixir
Neo4j.Client.clear_database
```

## Future Development Ideas

- [ ] Add Tests using [Mox](https://hexdocs.pm/mox/Mox.html) to interact with the Blockscout API and Neo4j.
- [ ] Create an Adapter for `Neo4j.Client`. This way the project can become agnostic on the underlying database provided that the new adapter specifies the Graph structure to be used. With it, we could explore SmartContracts in particular, and just use the project as tooling.
- [ ] Request more transactions per wallet, using the GraphQL cursors provided by Blockscout API, or using a different API.
- [ ] Explore through internal transactions, also.
