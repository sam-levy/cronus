defmodule Sig.Accounting.ChartOfAccounts.ChartOfAccountTest do
  use Sig.DataCase, async: true

  alias Sig.Accounting.ChartOfAccounts.ChartOfAccount

  describe "chart_of_accounts table base constraints" do
    test "[:name, :org_id] citext unique_constraint" do
      org = insert(:org)
      insert(:chart_of_account, org: org, name: "CHAIN 1")

      sector = %ChartOfAccount{
        org_id: org.id,
        name: "Chain 1"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/chart_of_accounts_name_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(sector) end
    end
  end

  describe "changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        name: "Chain 1"
      }

      assert changeset = ChartOfAccount.changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               name: attrs[:name],
               org_id: attrs[:org_id]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        name: :invalid
      }

      assert changeset = ChartOfAccount.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               name: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = ChartOfAccount.changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               name: ["can't be blank"]
             }
    end

    test "[:name, :org_id] citext unique constraint" do
      org = insert(:org)
      insert(:chart_of_account, org: org, name: "CHAIN 1")

      attrs = %{
        org_id: org.id,
        name: "Chain 1"
      }

      assert {:error, changeset} =
               attrs
               |> ChartOfAccount.changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["has already been taken"]
             }
    end
  end
end
