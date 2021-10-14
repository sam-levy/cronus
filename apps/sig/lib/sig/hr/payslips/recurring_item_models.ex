defmodule Sig.HR.Payslips.RecurringItemModels do
  import Ecto.Query

  alias Sig.HR.Payslips.RecurringItemModels.RecurringItemModel
  alias Sig.Organizations.Org
  alias Sig.Repo

  def list(%Org{} = org) do
    RecurringItemModel
    |> where(org_id: ^org.id)
    |> Repo.all()
  end
end
