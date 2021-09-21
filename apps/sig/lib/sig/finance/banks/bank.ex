defmodule Sig.Finance.Banks.Bank do
  fields = [:name, :routing_number]

  @enforce_keys fields
  defstruct fields

  @type t :: %__MODULE__{
          name: String.t(),
          routing_number: String.t()
        }
end
