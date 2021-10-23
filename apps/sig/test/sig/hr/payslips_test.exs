defmodule Sig.HR.PayslipsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips
  alias Sig.HR.Payslips.Payslip

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Payslip{}} = Payslips.create_change()
    end
  end

  describe "list_by_registration/1" do
    test "lists payslips by registration ordered by start date" do
      registration = insert(:employee_registration)

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-02-01]
      )

      insert(:payslip,
        org: registration.org,
        registration: registration,
        start_date: ~D[2021-01-01]
      )

      assert [
               %Payslip{start_date: ~D[2021-01-01]},
               %Payslip{start_date: ~D[2021-02-01]}
             ] = Payslips.list_by_registration(registration)
    end

    test "registration has no payslips" do
      registration = insert(:employee_registration)

      assert Payslips.list_by_registration(registration) == []
    end
  end

  describe "get/2" do
    test "returns a payslip" do
      registration = insert(:employee_registration)

      %{id: id} = insert(:payslip, org: registration.org, registration: registration)

      assert %Payslip{id: ^id} = Payslips.get(registration, id)
    end

    test "payslip belongs to another registration" do
      registration = insert(:employee_registration)
      another_registration = insert(:employee_registration)

      %{id: id} =
        insert(:payslip, org: another_registration.org, registration: another_registration)

      assert Payslips.get(registration, id) == nil
    end

    test "payslip doesn't exist" do
      registration = insert(:employee_registration)

      assert Payslips.get(registration, UUID.generate()) == nil
    end
  end

  describe "get_by/2" do
    test "gets a payslip by attrs" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      %{id: id} = insert(:payslip, org: org, registration: registration)

      assert %Payslip{id: ^id} = Payslips.get_by(id: id, org_id: org.id)
    end

    test "when field does't exist" do
      org = insert(:org)

      assert Payslips.get_by(id: UUID.generate(), org_id: org.id) == nil
    end
  end
end
