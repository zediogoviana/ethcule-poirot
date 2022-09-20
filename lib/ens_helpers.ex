defmodule EnsHelpers do
  @moduledoc false

  def check_for_ens(to_address, from_address) do
    Neuron.query(
      """
        query($from_address: ID!, $to_address: ID!) {
          fromAddress: domains(where: {resolvedAddress: $from_address}) {
            name
          }
          toAddress: domains(where: {resolvedAddress: $to_address}) {
            name
          }
        }
      """,
      %{to_address: to_address, from_address: from_address},
      url: "https://api.thegraph.com/subgraphs/name/ensdomains/ens"
    )
    |> parse_ens_response()
  end

  @spec parse_ens_response({:ok, any()}) :: map()
  defp parse_ens_response({:ok, %Neuron.Response{body: body}}) do
    to_ens = retrieve_ens_name(body["data"]["toAddress"])
    from_ens = retrieve_ens_name(body["data"]["fromAddress"])

    %{to_ens: to_ens, from_ens: from_ens}
  end

  @spec parse_ens_response({:error, any()}) :: map()
  defp parse_ens_response(_request_result) do
    %{to_ens: "", from_ens: ""}
  end

  @spec retrieve_ens_name(nil | list()) :: String.t()
  defp retrieve_ens_name(nil), do: ""
  defp retrieve_ens_name([]), do: ""
  defp retrieve_ens_name([head | _tail]), do: head["name"]
end
