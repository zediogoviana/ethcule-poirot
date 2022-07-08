defmodule Adapters.Api.Blockscout do
  @behaviour Behaviours.Api

  def initial_setup() do
    Neuron.Config.set(url: Application.fetch_env!(:ethcule_poirot, :api_url))

    Neuron.Config.set(
      connection_opts: [
        recv_timeout: Application.fetch_env!(:ethcule_poirot, :api_timeout)
      ]
    )

    :ok
  end

  def address_information(eth_address) do
    Neuron.query(
      """
        query($eth_address: AddressHash!) {
          address(hash: $eth_address) {
            contractCode
          }
        }
      """,
      %{eth_address: eth_address}
    )
  end

  def transactions_for_address(eth_address) do
    Neuron.query(
      """
        query($eth_address: AddressHash!) {
          address(hash: $eth_address) {
            contractCode
            transactions(first: 22) {
              edges {
                node {
                  hash
                  toAddressHash
                  fromAddressHash
                  value
                  status
                }
              }
              pageInfo {
                hasNextPage
              }
            }
          }
        }
      """,
      %{eth_address: eth_address}
    )
  end
end
