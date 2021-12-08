defmodule Sig.HR.Payslips.GroupsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Payslip
  alias Sig.HR.Payslips.Groups
  alias Sig.HR.Payslips.Groups.Group

  describe "list_by/1 Org" do
    test "lists groups by org ordered by date" do
      %{id: org_id} = org = insert(:org)

      insert(:payslip_group, org: org, date: ~D[2021-01-01])
      insert(:payslip_group, org: org, date: ~D[2021-02-01])

      assert [
               %Group{org_id: ^org_id, date: ~D[2021-02-01]},
               %Group{org_id: ^org_id, date: ~D[2021-01-01]}
             ] = Groups.list_by(org)
    end

    test "when org has no groups" do
      org = insert(:org)

      assert Groups.list_by(org) == []
    end
  end

  describe "get/1" do
    test "gets a group by org" do
      org = insert(:org)
      %{id: id} = insert(:payslip_group, org: org)

      assert %Group{id: ^id} = Groups.get(org, id)
    end

    test "when group belongs to another org" do
      org = insert(:org)
      %{id: id} = insert(:payslip_group, org: org)
      another_org = insert(:org)

      assert Groups.get(another_org, id) == nil
    end
  end

  describe "fetch_by/1" do
    test "fetches a group by attrs" do
      date = ~D[2021-01-01]
      type = :regular

      org = insert(:org)
      %{id: group_id} = insert(:payslip_group, org: org, date: date, type: type)

      assert {:ok, %Group{id: ^group_id}} =
               Groups.fetch_by(org_id: org.id, date: date, type: type)
    end

    test "group desn't exist" do
      date = ~D[2021-01-01]
      type = :regular

      org = insert(:org)
      insert(:payslip_group, org: org, date: date, type: type)

      assert Groups.fetch_by(org_id: org.id, date: ~D[2021-02-01], type: type) ==
               {:error, :not_found}
    end
  end

  describe "delete/1" do
    test "deletes a group" do
      %{id: id} = group = insert(:payslip_group)

      assert {:ok, %Group{id: ^id}} = Groups.delete(group)
    end

    test "group has already been deleted" do
      group = insert(:payslip_group)

      Repo.delete(group)

      assert Groups.delete(group) == {:error, :not_found}
    end
  end

  describe "delete_with_payslips/2" do
    test "delete group with payslips" do
      org = insert(:org)
      group = insert(:payslip_group, org: org, type: :regular, date: ~D[2021-01-01])

      payslips =
        insert_list(2, :payslip, org: org, group: group, start_date: ~D[2021-01-01], type: :regular)

      assert {:ok, %Group{}} =  Groups.delete_with_payslips(org, group)

      refute Repo.get_by(Group, org_id: org.id, id: group.id)

      Enum.each(payslips, fn payslip ->
        refute Repo.get(Payslip, org_id: org.id, id: payslip.id)
      end)
    end

    test "when group has no payslip" do
      org = insert(:org)
      group = insert(:payslip_group, org: org)

      assert {:ok, %Group{}} =  Groups.delete_with_payslips(org, group)

      refute Repo.get_by(Group, org_id: org.id, id: group.id)
    end
  end

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

      assert {:ok, {:existing, %Group{id: ^id}}} = Groups.provide(org, ~D[2021-01-01], :regular)
    end

    test "returns new group" do
      org = insert(:org)
      insert(:payslip_group, org: org, date: ~D[2021-01-01], type: :regular)

      assert {:ok, {:new, %Group{id: id}}} = Groups.provide(org, ~D[2021-01-01], :vacation)

      assert Repo.get_by(Group, id: id, date: ~D[2021-01-01], type: :vacation)
    end

    test "returns a new group when the date is not beginning of month" do
      org = insert(:org)

      assert {:ok, {:new, %Group{id: id}}} = Groups.provide(org, ~D[2021-01-15], :vacation)

      assert Repo.get_by(Group, id: id, date: ~D[2021-01-01], type: :vacation)
    end
  end
end
