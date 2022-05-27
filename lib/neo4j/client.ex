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
    delete_relationships = "MATCH (a) -[r] -> () DELETE a, r"
    delete_nodes = "MATCH (a) DELETE a"

    Neo.query(state.conn, delete_relationships)
    Neo.query(state.conn, delete_nodes)

    {:noreply, state}
  end

  def handle_info({:paint_node, eth_address, new_label_string}, state) do
    downcased_address = String.downcase(eth_address)

    cypher =
      """
        MATCH (n:Account)
        WHERE n.eth_address = '{{address}}'
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
    to_address = transaction["node"]["toAddressHash"]
    from_address = transaction["node"]["fromAddressHash"]

    next_address =
      if transaction["node"]["toAddressHash"] == eth_address do
        transaction["node"]["fromAddressHash"]
      else
        transaction["node"]["toAddressHash"]
      end

    cypher =
      """
        MERGE (AAA{{to_address}}:Account {eth_address: '{{to_address}}'})
        MERGE (AAA{{from_address}}:Account {eth_address: '{{from_address}}'})

        MERGE (AAA{{from_address}})-[:SENT {value: '{{value}}', status: '{{status}}'}]->(AAA{{to_address}})
      """
      |> Cypher.prepared_statement(
        to_address: to_address,
        from_address: from_address,
        value: transaction["node"]["value"],
        status: transaction["node"]["status"]
      )

    state.conn
    |> Neo.query(cypher)

    {:reply, next_address, state}
  end

  def clear_database do
    send(__MODULE__, :clear_database)
  end

  def paint_node(eth_address, new_label_string) do
    send(__MODULE__, {:paint_node, eth_address, new_label_string})
  end

  def highlight_accounts_of_interest(addresses) do
    send(__MODULE__, {:highlight_accounts_of_interest, addresses})
  end

  def transaction_relation(eth_address, transaction) do
    GenServer.call(__MODULE__, {:transaction_relation, eth_address, transaction})
  end
end
