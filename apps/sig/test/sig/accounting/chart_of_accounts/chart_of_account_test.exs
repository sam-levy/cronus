defmodule Sig.Accounting.ChartOfAccounts.ChartOfAccountTest do
  use Sig.DataCase, async: true

  alias Sig.Accounting.ChartOfAccounts.ChartOfAccount

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

    test "string field max length" do
      attrs = %{
        org_id: UUID.generate(),
        name: String.duplicate("a", 256)
      }

      assert changeset = ChartOfAccount.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["should be at most 255 character(s)"]
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

    test "insert changeset" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        name: "Chain 1"
      }

      assert {:ok, _coa} =
               attrs
               |> ChartOfAccount.changeset()
               |> Repo.insert()
    end
  end
end
