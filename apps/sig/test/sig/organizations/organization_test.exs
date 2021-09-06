defmodule Sig.Organizations.OrganizationTest do
  use Sig.DataCase

  alias Sig.Organizations.Organization

  describe "changeset/2" do
    test "valid params" do
      params = %{
        name: Faker.Company.name()
      }

      assert changeset = Organization.changeset(params)

      assert changeset.valid?
      assert changeset.changes == params
    end

    test "missing required params" do
      assert changeset = Organization.changeset(%{})

      refute changeset.valid?
      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "invalid params types" do
      params = %{
        name: :invalid_type
      }

      assert changeset = Organization.changeset(params)

      refute changeset.valid?
      assert errors_on(changeset) == %{name: ["is invalid"]}
    end

    test "string fields length greater than 255 chars" do
      params = %{
        name: String.duplicate("a", 256)
      }

      assert changeset = Organization.changeset(params)

      refute changeset.valid?
      assert errors_on(changeset) == %{name: ["should be at most 255 character(s)"]}
    end
  end
end
