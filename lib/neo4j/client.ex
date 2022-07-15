defmodule Neo4j.Client do
  @moduledoc false

  use GenServer
  alias Bolt.Sips, as: Neo
  alias Neo4j.Cypher

  def start_link(_initial_state) do
    initial_state = %{conn: Neo.conn()}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  def handle_info(:clear_database, state) do
    cypher = "MATCH (a)-[r]->(b) DELETE a, r, b"

    Neo.query(state.conn, cypher)

    {:noreply, state}
  end

  def handle_info(:create_indexes, state) do
    index_nodes = "CREATE INDEX EthAddressIndex IF NOT EXISTS FOR (a:Account) ON (a.eth_address)"

    index_rel = "CREATE INDEX TransactionHashIndex IF NOT EXISTS FOR ()-[s:SENT]-() ON (s.hash)"

    Neo.query(state.conn, index_nodes)
    Neo.query(state.conn, index_rel)

    {:noreply, state}
  end

  def handle_info({:paint_node, eth_address, new_label_string}, state) do
    downcased_address = String.downcase(eth_address)

    cypher =
      """
        MATCH (n:Account {eth_address: '{{address}}'})
        SET n:{{label}}
      """
      |> Cypher.prepared_statement(address: downcased_address, label: new_label_string)

    state.conn
    |> Neo.query(cypher)

    {:noreply, state}
  end

  def handle_info({:highlight_accounts_of_interest, addresses}, state) do
    addresses
    |> Enum.each(&paint_node(String.downcase(&1), "Interest"))

    {:noreply, state}
  end

  def handle_call({:transaction_relation, eth_address, transaction}, _from, state) do
    to_address = transaction.to_address
    from_address = transaction.from_address

    next_address =
      if to_address == eth_address do
        from_address
      else
        to_address
      end

    cypher =
      """
        MERGE (to:Account {eth_address: '{{to_address}}'})
        MERGE (from:Account {eth_address: '{{from_address}}'})

        MERGE (from)-[t:SENT {hash: '{{hash}}', eth_value: '{{value}}'}]->(to)
        SET t.status = '{{status}}'
      """
      |> Cypher.prepared_statement(
        to_address: to_address,
        from_address: from_address,
        hash: transaction.hash,
        value: transaction.value,
        status: transaction.status
      )

    state.conn
    |> Neo.query(cypher)

    {:reply, next_address, state}
  end

  def clear_database do
    send(__MODULE__, :clear_database)
  end

  def create_indexes do
    send(__MODULE__, :create_indexes)
  end

  def paint_node(eth_address, new_label_string) do
    send(__MODULE__, {:paint_node, eth_address, new_label_string})
  end

  def highlight_accounts_of_interest(addresses) do
    send(__MODULE__, {:highlight_accounts_of_interest, addresses})
  end

  def transaction_relation(eth_address, transaction) do
    GenServer.call(__MODULE__, {:transaction_relation, eth_address, transaction}, :infinity)
  end
end
