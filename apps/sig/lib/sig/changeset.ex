defmodule Sig.Changeset do
  import Ecto.Changeset, only: [validate_change: 3]

  alias Sig.Finance.Banks

  def validate_routing_number(changeset, field) do
    validate_change(
      changeset,
      field,
      fn field, routing_number ->
        if Banks.valid_routing_number?(routing_number) do
          []
        else
          [{field, "does not exist"}]
        end
      end
    )
  end
end
