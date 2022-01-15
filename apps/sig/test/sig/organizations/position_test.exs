defmodule Sig.Organizations.PositionTest do
  use Sig.DataCase, async: true

  alias Sig.Organizations.Position

  describe "org_positions table constraints" do
    test "org_id not_null_violation" do
      position = %Position{
        name: "store manager"
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(position) end
    end

    test "org_id foreign_key_constraint" do
      position = %Position{
        org_id: UUID.generate(),
        name: "store manager"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/org_positions_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert(position) end
    end

    test "name not_null_violation" do
      org = insert(:org)

      position = %Position{
        org_id: org.id
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"name\" of relation \"org_positions\" violates not-null constraint/,
                   fn -> Repo.insert(position) end
    end

    test "[:name, :org_id] citext unique_constraint" do
      org = insert(:org)
      insert(:org_position, org: org, name: "store manager")

      position = %Position{
        org_id: org.id,
        name: "STORE MANAGER"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/org_positions_name_org_id_index \(unique_constraint\)/,
                   fn -> Repo.insert(position) end
    end

    test "valid attrs" do
      org = insert(:org)

      position = %Position{
        org_id: org.id,
        name: "delivery person"
      }

      assert {:ok, _position} = Repo.insert(position)

      assert Repo.get_by(Position,
               org_id: org.id,
               name: "delivery person"
             )
    end
  end

  describe "changeset/2" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        name: "Position Name"
      }

      assert changeset = Position.changeset(attrs)

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

      assert changeset = Position.changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               name: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Position.changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               name: ["can't be blank"]
             }
    end

    test "name unique constraint" do
      org = insert(:org)

      insert(:org_position, org: org, name: "POSITION NAME")

      attrs = %{
        org_id: org.id,
        name: "Position Name"
      }

      assert {:error, changeset} =
               attrs
               |> Position.changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["has already been taken"]
             }
    end
  end
end
