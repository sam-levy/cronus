defmodule Sig.HR.Payslips.Groups do
  alias Sig.HR.Payslips.Groups.Group
  alias Sig.Organizations.Org
  alias Sig.Repo

  def create(%Org{} = org, %{} = attrs) do
    attrs
    |> Map.put(:org_id, org.id)
    |> Group.create_changeset()
    |> Repo.insert()
  end

  def provide(%Org{} = org, %Date{} = date, type) when is_atom(type) do
    date = Date.beginning_of_month(date)

    case Repo.get_by(Group, org_id: org.id, date: date, type: type) do
      %Group{} = group -> {:ok, group}
      nil -> create(org, %{date: date, type: type})
    end
  end
end
