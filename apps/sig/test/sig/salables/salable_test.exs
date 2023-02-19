defmodule Sig.Accounting.Salables.SalableTest do
  use Sig.DataCase, async: true

  alias Sig.Accounting.Salables.Salable

  describe "salables table base constraints" do
    test "unit string size" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      salable = %Salable{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "INVALID_UNIT",
        entity_id: entity.id
      }

      assert_raise Postgrex.Error,
                   ~r/value too long for type character varying\(10\)/,
                   fn -> Repo.insert(salable) end
    end

    test "salables_unit_uppercase constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      salable = %Salable{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "gramas",
        entity_id: entity.id
      }

      assert_raise Ecto.ConstraintError,
                   ~r/salables_unit_uppercase \(check_constraint\)/,
                   fn -> Repo.insert(salable) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "KG",
        entity_id: UUID.generate()
      }

      assert changeset = Salable.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               type: attrs[:type],
               code: attrs[:code],
               description: attrs[:description],
               unit: attrs[:unit],
               entity_id: attrs[:entity_id]
             }
    end

    test "invalid attrs" do
      attrs = %{
        org_id: :invalid,
        type: :invalid,
        code: :invalid,
        description: :invalid,
        unit: :invalid,
        entity_id: :invalid
      }

      assert changeset = Salable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               type: ["is invalid"],
               code: ["is invalid"],
               description: ["is invalid"],
               unit: ["is invalid"],
               entity_id: ["is invalid"]
             }
    end

    test "missing required attrs" do
      assert changeset = Salable.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               type: ["can't be blank"],
               code: ["can't be blank"],
               description: ["can't be blank"],
               unit: ["can't be blank"],
               entity_id: ["can't be blank"]
             }
    end

    test "string fields length greater than limit" do
      attrs = %{
        org_id: UUID.generate(),
        type: random_enum_value(:salable_type),
        code: String.duplicate("a", 51),
        description: String.duplicate("a", 51),
        unit: "KG",
        entity_id: UUID.generate()
      }

      assert changeset = Salable.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["should be at most 50 character(s)"],
               description: ["should be at most 50 character(s)"]
             }
    end

    test "entity_id assoc constraint" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "KG",
        entity_id: UUID.generate()
      }

      assert {:error, changeset} =
               attrs
               |> Salable.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               entity: ["does not exist"]
             }
    end

    test "invalid unit" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      attrs = %{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "INVALD",
        entity_id: entity.id
      }

      assert {:error, changeset} =
               attrs
               |> Salable.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               unit: ["does not exist"]
             }
    end

    test "[:code, :entity_id, :org_id] citext unique constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:salable, org: org, code: "aa11", entity: entity)

      attrs = %{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: "AA11",
        description: Faker.Commerce.product_name(),
        unit: "KG",
        entity_id: entity.id
      }

      assert {:error, changeset} =
               attrs
               |> Salable.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["has already been taken"]
             }
    end

    test "[:description, :entity_id, :org_id] citext unique constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:salable, org: org, description: "product 1", entity: entity)

      attrs = %{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: "PRODUCT 1",
        unit: "KG",
        entity_id: entity.id
      }

      assert {:error, changeset} =
               attrs
               |> Salable.create_changeset()
               |> Repo.insert()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["has already been taken"]
             }
    end

    test "insert changeset" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      attrs = %{
        org_id: org.id,
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "KG",
        entity_id: entity.id
      }

      assert {:ok, _salable} =
               attrs
               |> Salable.create_changeset()
               |> Repo.insert()
    end
  end

  describe "update_changeset/1" do
    test "valid attrs" do
      salable = insert(:salable, type: :service)

      attrs = %{
        type: :good,
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "GR"
      }

      assert changeset = Salable.update_changeset(salable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: attrs[:type],
               code: attrs[:code],
               description: attrs[:description],
               unit: attrs[:unit]
             }
    end

    test "ignores non permitted attrs" do
      salable = insert(:salable, type: :service)

      attrs = %{
        org_id: UUID.generate(),
        type: :good,
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "GR",
        entity_id: UUID.generate()
      }

      assert changeset = Salable.update_changeset(salable, attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               type: attrs[:type],
               code: attrs[:code],
               description: attrs[:description],
               unit: attrs[:unit]
             }
    end

    test "string fields length greater than limit" do
      salable = insert(:salable)

      attrs = %{
        type: random_enum_value(:salable_type),
        code: String.duplicate("a", 51),
        description: String.duplicate("a", 51),
        unit: "GR"
      }

      assert changeset = Salable.update_changeset(salable, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["should be at most 50 character(s)"],
               description: ["should be at most 50 character(s)"]
             }
    end

    test "invalid unit" do
      salable = insert(:salable)

      attrs = %{
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "INVALD"
      }

      assert {:error, changeset} =
               salable
               |> Salable.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               unit: ["does not exist"]
             }
    end

    test "[:code, :entity_id, :org_id] citext unique constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:salable, org: org, code: "aa11", entity: entity)

      salable = insert(:salable, org: org, entity: entity)

      attrs = %{
        type: random_enum_value(:salable_type),
        code: "AA11",
        description: Faker.Commerce.product_name(),
        unit: "GR"
      }

      assert {:error, changeset} =
               salable
               |> Salable.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               code: ["has already been taken"]
             }
    end

    test "[:description, :entity_id, :org_id] citext unique constraint" do
      org = insert(:org)
      entity = insert(:entity, org: org)

      insert(:salable, org: org, description: "product 1", entity: entity)

      salable = insert(:salable, org: org, entity: entity)

      attrs = %{
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: "PRODUCT 1",
        unit: "KG"
      }

      assert {:error, changeset} =
               salable
               |> Salable.update_changeset(attrs)
               |> Repo.update()

      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["has already been taken"]
             }
    end

    test "update changeset" do
      salable = insert(:salable)

      attrs = %{
        type: random_enum_value(:salable_type),
        code: random_string_number(5),
        description: Faker.Commerce.product_name(),
        unit: "KG"
      }

      assert {:ok, _salable} =
               salable
               |> Salable.update_changeset(attrs)
               |> Repo.update()
    end
  end
end
