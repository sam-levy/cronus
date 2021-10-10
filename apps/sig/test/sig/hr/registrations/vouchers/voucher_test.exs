defmodule Sig.HR.Registrations.Vouchers.VoucherTest do
  use Sig.DataCase

  alias Sig.HR.Registrations.Vouchers.Voucher

  describe "employee_vouchers table constraints" do
    test "org_id not_null_violation" do
      registration = insert(:employee_registration)

      voucher = %Voucher{
        registration_id: registration.id,
        type: random_enum_value(:employee_voucher_type),
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"employee_vouchers\" violates not-null constraint/,
                   fn -> Repo.insert(voucher) end
    end

    test "org_id foreign_key_constraint" do
      registration = insert(:employee_registration)

      voucher = %Voucher{
        org_id: UUID.generate(),
        registration_id: registration.id,
        type: random_enum_value(:employee_voucher_type),
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_vouchers_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(voucher) end
    end

    test "registration_id not_null_violation" do
      org = insert(:org)

      voucher = %Voucher{
        org_id: org.id,
        type: random_enum_value(:employee_voucher_type),
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"registration_id\" of relation \"employee_vouchers\" violates not-null constraint/,
                   fn -> Repo.insert(voucher) end
    end

    test "registration_id foreign_key_constraint" do
      org = insert(:org)

      voucher = %Voucher{
        org_id: org.id,
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_voucher_type),
        amount: Enum.random(400_00..600_00),
        start_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_vouchers_registration_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(voucher) end
    end

    test "[:type, :registration_id, :org_id] conditional unique_constraint" do
      org = insert(:org)
      registration = insert(:employee_registration, org: org)

      # Existing valid transport voucher
      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :transport,
        start_date: ~D[2021-01-01],
        end_date: nil
      )

      # Allow different valid voucher type
      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :meal,
        start_date: ~D[2021-01-01],
        end_date: nil
      )

      # Allow same voucher type when expired
      insert(:employee_voucher,
        org: org,
        registration: registration,
        type: :meal,
        start_date: ~D[2019-01-01],
        end_date: ~D[2020-02-01]
      )

      # Allow same voucher type for different registration
      insert(:employee_voucher,
        org: org,
        type: :transport,
        start_date: ~D[2021-01-01],
        end_date: nil
      )

      voucher = %Voucher{
        org_id: org.id,
        registration_id: registration.id,
        type: :transport,
        amount: 500_00,
        start_date: ~D[2021-02-01],
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_salaries_type_unique_when_end_date_null \(unique_constraint\)/,
                   fn -> Repo.insert(voucher) end
    end

    test "employee_vouchers_amount_greater_than_zero constraint" do
      registration = insert(:employee_registration)

      voucher = %Voucher{
        org_id: registration.org_id,
        registration_id: registration.id,
        type: random_enum_value(:employee_voucher_type),
        amount: -400_00,
        start_date: Faker.Date.backward(100)
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_vouchers_amount_greater_than_zero \(check_constraint\)/,
                   fn -> Repo.insert(voucher) end
    end

    test "employee_vouchers_start_date_before_end_date constraint" do
      registration = insert(:employee_registration)

      voucher = %Voucher{
        org_id: registration.org_id,
        registration_id: registration.id,
        type: random_enum_value(:employee_voucher_type),
        amount: Enum.random(400_00..600_00),
        start_date: ~D[2021-01-01],
        end_date: ~D[2020-01-01]
      }

      assert_raise Ecto.ConstraintError,
                   ~r/employee_vouchers_start_date_before_end_date \(check_constraint\)/,
                   fn -> Repo.insert(voucher) end
    end
  end

  describe "create_changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_voucher_type),
        amount: 500_00,
        start_date: Faker.Date.backward(100)
      }

      assert changeset = Voucher.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        registration_id: attrs[:registration_id],
        type: attrs[:type],
        amount: %Money{amount: attrs[:amount], currency: :BRL},
        start_date: attrs[:start_date],
      }
    end

    test "missing required attrs" do
      assert changeset = Voucher.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
        amount: ["can't be blank"],
        org_id: ["can't be blank"],
        registration_id: ["can't be blank"],
        start_date: ["can't be blank"],
        type: ["can't be blank"]
      }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        registration_id: :invalid,
        type: :invalid,
        amount: :invalid,
        start_date: :invalid
      }

      assert changeset = Voucher.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        amount: ["is invalid"],
        org_id: ["is invalid"],
        registration_id: ["is invalid"],
        start_date: ["is invalid"],
        type: ["is invalid"]
      }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_voucher_type),
        amount: 500_00,
        start_date: Faker.Date.backward(100),
        end_date: Faker.Date.backward(1)
      }

      assert changeset = Voucher.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        org_id: attrs[:org_id],
        registration_id: attrs[:registration_id],
        type: attrs[:type],
        amount: %Money{amount: attrs[:amount], currency: :BRL},
        start_date: attrs[:start_date],
      }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_voucher_type),
        amount: -500_00,
        start_date: Faker.Date.backward(100)
      }

      assert changeset = Voucher.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{amount: ["must be greater than 0,00"]}
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: ~D[2021-01-01]
      }

      assert changeset = Voucher.update_changeset(voucher, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        end_date: attrs[:end_date]
      }
    end

    test "missing required attrs" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      assert changeset = Voucher.update_changeset(voucher, %{})

      refute changeset.valid?

      assert errors_on(changeset) == %{end_date: ["can't be blank"]}
    end

    test "invalid attrs" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: :invalid
      }

      assert changeset = Voucher.update_changeset(voucher, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{end_date: ["is invalid"]}
    end

    test "ignores non permitted attrs" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        org_id: UUID.generate(),
        registration_id: UUID.generate(),
        type: random_enum_value(:employee_voucher_type),
        amount: 500_00,
        start_date: ~D[2020-02-01],
        end_date: ~D[2021-01-01]
      }

      assert changeset = Voucher.update_changeset(voucher, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
        end_date: attrs[:end_date]
      }
    end

    test "end_date before start_date" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: ~D[2019-01-01]
      }

      assert changeset = Voucher.update_changeset(voucher, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        end_date: ["must be after start_date"]
      }
    end

    test "end_date equal to start_date" do
      voucher = insert(:employee_voucher, start_date: ~D[2020-01-01], end_date: nil)

      attrs = %{
        end_date: ~D[2020-01-01]
      }

      assert changeset = Voucher.update_changeset(voucher, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
        end_date: ["must be after start_date"]
      }
    end
  end
end
