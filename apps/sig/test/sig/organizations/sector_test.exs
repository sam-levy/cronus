defmodule Sig.Organizations.SectorTest do
  use Sig.DataCase

  alias Sig.Organizations.Sector

  describe "org_sectors table constraints" do
    test "org_id not_null_violation" do
      sector = %Sector{
        name: "kitchen"
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"org_sectors\" violates not-null constraint/,
                   fn -> Repo.insert(sector) end
    end

    test "org_id foreign_key_constraint" do
      sector = %Sector{
        org_id: UUID.generate(),
        name: "kitchen"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/org_sectors_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(sector) end
    end

    test "name not_null_violation" do
      org = insert(:org)

      sector = %Sector{
        org_id: org.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"name\" of relation \"org_sectors\" violates not-null constraint/,
                   fn -> Repo.insert(sector) end
    end

    test "[:name, :org_id] citext unique_constraint" do
      org = insert(:org)
      insert(:org_sector, org: org, name: "kitchen")

      sector = %Sector{
        org_id: org.id,
        name: "KITCHEN"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/org_sectors_name_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(sector) end
    end

    test "valid attrs" do
      org = insert(:org)

      sector = %Sector{
        org_id: org.id,
        name: "delivery"
      }

      assert {:ok, _sector} = Repo.insert(sector)

      assert Repo.get_by(Sector,
               org_id: org.id,
               name: "delivery"
             )
    end
  end

  describe "changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        name: "Sector Name"
      }

      assert changeset = Sector.changeset(attrs)

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

      assert changeset = Sector.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               name: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Sector.changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               name: ["can't be blank"]
             }
    end

    test "name unique constraint" do
      org = insert(:org)

      insert(:org_sector, org: org, name: "SECTOR NAME")

      attrs = %{
        org_id: org.id,
        name: "Sector Name"
      }

      assert {:error, changeset} =
               attrs
               |> Sector.changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["has already been taken"]
             }
    end
  end
end
