defmodule Sig.HR.Registrations.Vouchers.CreateTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Vouchers.Voucher
  alias Sig.HR.Registrations.Vouchers.Create

  describe "call/3" do
    test "creates a voucher when none exist" do
      registration = insert(:employee_registration)

      attrs = %{
        type: random_enum_value(:employee_voucher_type),
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert {:ok, %Voucher{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Voucher,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               type: attrs[:type],
               amount: attrs[:amount],
               start_date: attrs[:start_date]
             )
    end

    test "returns changeset errors" do
      registration = insert(:employee_registration)

      assert {:error, changeset} = Create.call(registration, %{})

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               start_date: ["can't be blank"],
               type: ["can't be blank"]
             }
    end

    test "same type voucher in effect" do
      registration = insert(:employee_registration)

      insert(:employee_voucher,
        org: registration.org,
        registration: registration,
        type: :transport,
        end_date: nil
      )

      attrs = %{
        type: :transport,
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert Create.call(registration, attrs) ==
               {:error, "existe um vale do mesmo tipo em vigência"}
    end

    test "start_date before end_date of the last voucher from the same type" do
      registration = insert(:employee_registration)

      insert(:employee_voucher,
        org: registration.org,
        registration: registration,
        type: :transport,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      attrs = %{
        type: :transport,
        amount: Enum.random(400_00..600_00),
        start_date: ~D[2020-01-01]
      }

      assert Create.call(registration, attrs) ==
               {:error,
                "a data de início deve ser posterior a data de término do último vale do mesmo tipo"}
    end

    test "creates a voucher when others already exist" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # defferent type voucher in effect
      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :food,
        end_date: nil
      )

      # expired voucher from the same type
      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :transport,
        start_date: ~D[2019-01-01],
        end_date: ~D[2021-01-01]
      )

      # same type voucher in effect from another company
      insert(:employee_voucher,
        org: org,
        type: :transport,
        end_date: nil
      )

      attrs = %{
        type: :transport,
        amount: Enum.random(400_00..600_00),
        start_date: ~D[2021-01-02]
      }

      assert {:ok, %Voucher{id: id}} = Create.call(registration, attrs)

      assert Repo.get_by(Voucher,
               id: id,
               org_id: registration.org_id,
               registration_id: registration.id,
               type: attrs[:type],
               amount: attrs[:amount],
               start_date: attrs[:start_date]
             )
    end
  end
end
