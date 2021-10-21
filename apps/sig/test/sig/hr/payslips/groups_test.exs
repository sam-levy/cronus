defmodule Sig.HR.Payslips.GroupsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Groups
  alias Sig.HR.Payslips.Groups.Group

  describe "create/2" do
    test "creates a group" do
      org = insert(:org)

      attrs = %{
        date: ~D[2020-01-01],
        type: random_enum_value(:payslip_group_type)
      }

      assert {:ok, %Group{id: id}} = Groups.create(org, attrs)

      assert Repo.get_by(Group, id: id, date: attrs[:date], type: attrs[:type])
    end
  end

  describe "provide/2" do
    test "returns existing group" do
      org = insert(:org)
      %{id: id} = insert(:payslip_group, org: org, date: ~D[2021-01-01], type: :regular)

      assert {:ok, %Group{id: ^id}} = Groups.provide(org, ~D[2021-01-01], :regular)
    end

    test "returns new group" do
      org = insert(:org)
      insert(:payslip_group, org: org, date: ~D[2021-01-01], type: :regular)

      assert {:ok, %Group{id: id}} = Groups.provide(org, ~D[2021-01-01], :vacation)

      assert Repo.get_by(Group, id: id, date: ~D[2021-01-01], type: :vacation)
    end

    test "returns a new group when the date is not beginning of month" do
      org = insert(:org)

      assert {:ok, %Group{id: id}} = Groups.provide(org, ~D[2021-01-15], :vacation)

      assert Repo.get_by(Group, id: id, date: ~D[2021-01-01], type: :vacation)
    end
  end
end
