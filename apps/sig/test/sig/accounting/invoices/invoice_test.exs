defmodule Sig.Accounting.Invoices.InvoiceTest do
  use Sig.DataCase, async: true

  alias Sig.Accounting.Invoices.Invoice

  describe "invoices table base constraints" do
    test "invoices_amount_positive constraint" do
      org = insert(:org)
      invoiced_by = insert(:entity, org: org, type: :company)
      invoiced_to = insert(:entity, org: org, type: :company)

      invoice = %Invoice{
        org_id: org.id,
        type: random_enum_value(:invoice_type),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        invoiced_by_id: invoiced_by.id,
        invoiced_to_id: invoiced_to.id,
        amount: -1
      }

      assert_raise Ecto.ConstraintError,
                   ~r/invoices_amount_positive \(check_constraint\)/,
                   fn -> Repo.insert(invoice) end
    end
  end

  describe "create_non_nfe_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_non_nfe_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: :goods_and_services,
               number: attrs[:number],
               issue_date: attrs[:issue_date],
               delivery_date: attrs[:delivery_date],
               invoiced_by_id: attrs[:invoiced_by_id],
               invoiced_to_id: attrs[:invoiced_to_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        number: :invalid,
        issue_date: :invalid,
        delivery_date: :invalid,
        invoiced_by_id: :invalid,
        invoiced_to_id: :invalid,
        amount: :invalid
      }

      assert changeset = Invoice.create_non_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               number: ["is invalid"],
               issue_date: ["is invalid"],
               delivery_date: ["is invalid"],
               invoiced_by_id: ["is invalid"],
               invoiced_to_id: ["is invalid"],
               amount: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Invoice.create_non_nfe_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               number: ["can't be blank"],
               issue_date: ["can't be blank"],
               invoiced_by_id: ["can't be blank"],
               invoiced_to_id: ["can't be blank"],
               amount: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00),
        nfe_access_key: random_string_number(44),
        type: :tax
      }

      assert changeset = Invoice.create_non_nfe_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: :goods_and_services,
               number: attrs[:number],
               issue_date: attrs[:issue_date],
               delivery_date: attrs[:delivery_date],
               invoiced_by_id: attrs[:invoiced_by_id],
               invoiced_to_id: attrs[:invoiced_to_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: -1
      }

      assert changeset = Invoice.create_non_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "string fields length greater than limit" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(10),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_non_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               number: ["should be at most 9 character(s)"]
             }
    end

    test "string number numericality" do
      attrs = %{
        org_id: UUID.generate(),
        number: 123,
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_non_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               number: ["is invalid"]
             }
    end

    test "insert changeset" do
      org = insert(:org)
      invoiced_by = insert(:entity, org: org)
      invoiced_to = insert(:entity, org: org)

      attrs = %{
        org_id: org.id,
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: invoiced_by.id,
        invoiced_to_id: invoiced_to.id,
        amount: Enum.random(100_00..5_000_00)
      }

      assert {:ok, _invoice} =
               attrs
               |> Invoice.create_non_nfe_changeset()
               |> Repo.insert()
    end
  end

  describe "create_nfe_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        nfe_access_key: random_string_number(44),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_nfe_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: :goods_and_services,
               nfe_access_key: attrs[:nfe_access_key],
               number: attrs[:number],
               issue_date: attrs[:issue_date],
               delivery_date: attrs[:delivery_date],
               invoiced_by_id: attrs[:invoiced_by_id],
               invoiced_to_id: attrs[:invoiced_to_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        nfe_access_key: :invalid,
        number: :invalid,
        issue_date: :invalid,
        delivery_date: :invalid,
        invoiced_by_id: :invalid,
        invoiced_to_id: :invalid,
        amount: :invalid
      }

      assert changeset = Invoice.create_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               number: ["is invalid"],
               nfe_access_key: ["is invalid"],
               issue_date: ["is invalid"],
               delivery_date: ["is invalid"],
               invoiced_by_id: ["is invalid"],
               invoiced_to_id: ["is invalid"],
               amount: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Invoice.create_nfe_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               nfe_access_key: ["can't be blank"],
               number: ["can't be blank"],
               issue_date: ["can't be blank"],
               invoiced_by_id: ["can't be blank"],
               invoiced_to_id: ["can't be blank"],
               amount: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        nfe_access_key: random_string_number(44),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00),
        type: :tax
      }

      assert changeset = Invoice.create_nfe_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: :goods_and_services,
               nfe_access_key: attrs[:nfe_access_key],
               number: attrs[:number],
               issue_date: attrs[:issue_date],
               delivery_date: attrs[:delivery_date],
               invoiced_by_id: attrs[:invoiced_by_id],
               invoiced_to_id: attrs[:invoiced_to_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        nfe_access_key: random_string_number(44),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: -1
      }

      assert changeset = Invoice.create_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "string fields length greater than limit" do
      attrs = %{
        org_id: UUID.generate(),
        nfe_access_key: random_string_number(45),
        number: random_string_number(10),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               number: ["should be at most 9 character(s)"],
               nfe_access_key: ["should be at most 44 character(s)"]
             }
    end

    test "string number numericality" do
      attrs = %{
        org_id: UUID.generate(),
        nfe_access_key: 123,
        number: 123,
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_nfe_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               nfe_access_key: ["is invalid"],
               number: ["is invalid"]
             }
    end

    test "insert changeset" do
      org = insert(:org)
      invoiced_by = insert(:entity, org: org)
      invoiced_to = insert(:entity, org: org)

      attrs = %{
        org_id: org.id,
        nfe_access_key: random_string_number(44),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: invoiced_by.id,
        invoiced_to_id: invoiced_to.id,
        amount: Enum.random(100_00..5_000_00)
      }

      assert {:ok, _invoice} =
               attrs
               |> Invoice.create_nfe_changeset()
               |> Repo.insert()
    end
  end

  describe "create_tax_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_tax_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: :tax,
               number: attrs[:number],
               issue_date: attrs[:issue_date],
               invoiced_by_id: attrs[:invoiced_by_id],
               invoiced_to_id: attrs[:invoiced_to_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        number: :invalid,
        issue_date: :invalid,
        invoiced_by_id: :invalid,
        invoiced_to_id: :invalid,
        amount: :invalid
      }

      assert changeset = Invoice.create_tax_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               number: ["is invalid"],
               issue_date: ["is invalid"],
               invoiced_by_id: ["is invalid"],
               invoiced_to_id: ["is invalid"],
               amount: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Invoice.create_tax_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               number: ["can't be blank"],
               issue_date: ["can't be blank"],
               invoiced_by_id: ["can't be blank"],
               invoiced_to_id: ["can't be blank"],
               amount: ["can't be blank"]
             }
    end

    test "ignores non permitted attrs" do
      attrs = %{
        org_id: UUID.generate(),
        nfe_access_key: random_string_number(44),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        delivery_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00),
        type: :goods_and_services
      }

      assert changeset = Invoice.create_tax_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: :tax,
               number: attrs[:number],
               issue_date: attrs[:issue_date],
               invoiced_by_id: attrs[:invoiced_by_id],
               invoiced_to_id: attrs[:invoiced_to_id],
               amount: %Money{amount: attrs[:amount], currency: :BRL}
             }
    end

    test "negative amount" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(9),
        issue_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: -1
      }

      assert changeset = Invoice.create_tax_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               amount: ["must be greater than or equal to 0,00"]
             }
    end

    test "string fields length greater than limit" do
      attrs = %{
        org_id: UUID.generate(),
        number: random_string_number(10),
        issue_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_tax_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               number: ["should be at most 9 character(s)"]
             }
    end

    test "string number numericality" do
      attrs = %{
        org_id: UUID.generate(),
        number: 123,
        issue_date: random_past_date(30),
        invoiced_by_id: UUID.generate(),
        invoiced_to_id: UUID.generate(),
        amount: Enum.random(100_00..5_000_00)
      }

      assert changeset = Invoice.create_tax_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               number: ["is invalid"]
             }
    end

    test "insert changeset" do
      org = insert(:org)
      invoiced_by = insert(:entity, org: org)
      invoiced_to = insert(:entity, org: org)

      attrs = %{
        org_id: org.id,
        number: random_string_number(9),
        issue_date: random_past_date(30),
        invoiced_by_id: invoiced_by.id,
        invoiced_to_id: invoiced_to.id,
        amount: Enum.random(100_00..5_000_00)
      }

      assert {:ok, _invoice} =
               attrs
               |> Invoice.create_tax_changeset()
               |> Repo.insert()
    end
  end
end
