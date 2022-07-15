defmodule Address do
  defstruct [:eth_address, :contract, :transactions]

  @type t :: %__MODULE__{
          eth_address: String.t(),
          contract: boolean(),
          transactions: list(Transaction.t())
        }
end
