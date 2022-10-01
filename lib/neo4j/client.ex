defmodule Neo4j.Client do
  @moduledoc false

  use GenServer
  alias Bolt.Sips, as: Neo
  alias Neo4j.Cypher

  @spec start_link(any()) :: any()
  def start_link(_initial_state) do
    initial_state = %{conn: Neo.conn()}
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_info(:clear_database, state) do
    cypher = """
      MATCH (a)-[r]->(b) DELETE a, r, b;
      MATCH (c) DELETE c
    """

    Neo.query(state.conn, cypher)

    {:noreply, state}
  end

  @impl true
  def handle_info(:create_indexes, state) do
    indexes = """
      CREATE INDEX AccountAddressIndex IF NOT EXISTS FOR (a:Account) ON (a.eth_address);
      CREATE INDEX ContractAddressIndex IF NOT EXISTS FOR (a:SmartContract) ON (a.eth_address);
      CREATE INDEX TransactionHashIndex IF NOT EXISTS FOR ()-[s:TO]-() ON (s.hash)
    """

    Neo.query(state.conn, indexes)

    {:noreply, state}
  end

  @impl true
  def handle_info({:set_node_label, eth_address, new_label_string}, state) do
    downcased_address = String.downcase(eth_address || "")

    cypher =
      """
        MATCH (n {eth_address: '{{address}}'})
        SET n:{{label}}
      """
      |> Cypher.prepared_statement(address: downcased_address, label: new_label_string)

    state.conn
    |> Neo.query(cypher)

    {:noreply, state}
  end

  @impl true
  def handle_info({:highlight_accounts_of_interest, addresses}, state) do
    addresses
    |> Enum.each(&set_node_label(String.downcase(&1), "Interest"))

    {:noreply, state}
  end

  @impl true
  def handle_call({:transaction_relation, address_information, transaction}, _from, state) do
    to_address = transaction.to_address
    from_address = transaction.from_address

    next_address =
      if to_address == address_information.eth_address do
        from_address
      else
        to_address
      end

    ens_names = EnsHelpers.check_for_ens(to_address, from_address)

    cypher =
      """
        MERGE (current {eth_address: '{{current_address}}'})
        SET current:{{node_label}};

        MERGE (to {eth_address: '{{to_address}}'})
        MERGE (from {eth_address: '{{from_address}}'})
        SET to.ens_name = '{{to_ens}}', from.ens_name = '{{from_ens}}'

        MERGE (from)-[t:TO {hash: '{{hash}}', eth_value: '{{value}}'}]->(to)
        SET t.status = '{{status}}'
      """
      |> Cypher.prepared_statement(
        node_label: current_node_label(address_information.contract),
        current_address: address_information.eth_address,
        to_address: to_address,
        from_address: from_address,
        hash: transaction.hash,
        value: transaction.value,
        status: transaction.status,
        to_ens: ens_names.to_ens,
        from_ens: ens_names.from_ens
      )

    state.conn
    |> Neo.query(cypher)

    {:reply, next_address, state}
  end

  @spec clear_database() :: any()
  def clear_database do
    send(__MODULE__, :clear_database)
  end

  @spec create_indexes() :: any()
  def create_indexes do
    send(__MODULE__, :create_indexes)
  end

  @spec set_node_label(String.t(), String.t()) :: any()
  def set_node_label(eth_address, new_label_string) do
    send(__MODULE__, {:set_node_label, eth_address, new_label_string})
  end

  @spec highlight_accounts_of_interest(String.t()) :: any()
  def highlight_accounts_of_interest(addresses) do
    send(__MODULE__, {:highlight_accounts_of_interest, addresses})
  end

  @spec transaction_relation(Address.t(), Transaction.t()) :: String.t()
  def transaction_relation(eth_address, transaction) do
    GenServer.call(__MODULE__, {:transaction_relation, eth_address, transaction}, :infinity)
  end

  @spec current_node_label(boolean() | nil) :: String.t()
  defp current_node_label(true), do: "SmartContract"
  defp current_node_label(_), do: "Account"
end
