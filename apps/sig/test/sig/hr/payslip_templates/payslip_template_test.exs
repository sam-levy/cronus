defmodule Sig.HR.PayslipTemplates.PayslipTemplateTest do
  use Sig.DataCase, async: true

  alias Sig.HR.PayslipTemplates.PayslipTemplate

  describe "payslip_templates table constraints" do
    test "org_id not_null_violation" do
      payslip_template = %PayslipTemplate{
        name: "Template 1"
      }

      assert_raise Postgrex.Error,
                   ~r/\(not_null_violation\) null value in column \"org_id\" of relation \"payslip_templates\" violates not-null constraint/,
                   fn -> Repo.insert!(payslip_template) end
    end

    test "org_id foreign_key_constraint" do
      payslip_template = %PayslipTemplate{
        org_id: UUID.generate(),
        name: "Template 1"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_templates_org_id_fkey \(foreign_key_constraint\)/,
                   fn -> Repo.insert!(payslip_template) end
    end

    test "[:name, :org_id] citext unique_constraint" do
      org = insert(:org)
      insert(:payslip_template, org: org, name: "Template Name")

      # Allow same name for different org
      insert(:payslip_template, name: "TEMPLATE NAME")

      payslip_template = %PayslipTemplate{
        org_id: org.id,
        name: "TEMPLATE NAME"
      }

      assert_raise Ecto.ConstraintError,
                   ~r/payslip_templates_name_unique \(unique_constraint\)/,
                   fn -> Repo.insert!(payslip_template) end
    end
  end

  describe "create_changeset/1" do
    test "valid attrs" do
      attrs = %{
        org_id: UUID.generate(),
        name: Faker.Commerce.department()
      }

      assert changeset = PayslipTemplate.create_changeset(attrs)

      assert changeset.valid?

      assert changeset.changes == %{
               org_id: attrs[:org_id],
               name: attrs[:name]
             }
    end

    test "missing required attrs" do
      assert changeset = PayslipTemplate.create_changeset(%{})

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["can't be blank"],
               name: ["can't be blank"]
             }
    end

    test "invalid attrs types" do
      attrs = %{
        org_id: :invalid,
        name: :invalid
      }

      assert changeset = PayslipTemplate.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               org_id: ["is invalid"],
               name: ["is invalid"]
             }
    end

    test "name length greater than 255 chars" do
      attrs = %{
        org_id: UUID.generate(),
        name: String.duplicate("a", 256)
      }

      assert changeset = PayslipTemplate.create_changeset(attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["should be at most 255 character(s)"]
             }
    end

    test "[:name, :org_id] unique_constraint" do
      org = insert(:org)
      insert(:payslip_template, org: org, name: "Template Name")

      attrs = %{
        org_id: org.id,
        name: "Template Name"
      }

      assert {:error, changeset} =
               attrs
               |> PayslipTemplate.create_changeset()
               |> Repo.insert()

      assert errors_on(changeset) == %{
               name: ["has already been taken"]
             }
    end
  end

  describe "update_changeset/2" do
    test "valid attrs" do
      payslip_template = insert(:payslip_template)

      attrs = %{
        name: "New Name"
      }

      assert changeset = PayslipTemplate.update_changeset(payslip_template, attrs)

      assert changeset.valid?

      assert changeset.changes == %{name: attrs[:name]}
    end

    test "nil required attrs" do
      payslip_template = insert(:payslip_template)

      attrs = %{name: nil}

      assert changeset = PayslipTemplate.update_changeset(payslip_template, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{name: ["can't be blank"]}
    end

    test "ignores non permittet attrs" do
      payslip_template = insert(:payslip_template)

      attrs = %{
        org_id: UUID.generate(),
        name: "New Name"
      }

      assert changeset = PayslipTemplate.update_changeset(payslip_template, attrs)

      assert changeset.valid?

      assert changeset.changes == %{name: attrs[:name]}
    end

    test "name length greater than 255 chars" do
      payslip_template = insert(:payslip_template)

      attrs = %{
        name: String.duplicate("a", 256)
      }

      assert changeset = PayslipTemplate.update_changeset(payslip_template, attrs)

      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["should be at most 255 character(s)"]
             }
    end

    test "[:name, :org_id] unique_constraint" do
      org = insert(:org)

      insert(:payslip_template, org: org, name: "Template Name")

      template_item = insert(:payslip_template, org: org)

      attrs = %{
        name: "Template Name"
      }

      assert {:error, changeset} =
               template_item
               |> PayslipTemplate.update_changeset(attrs)
               |> Repo.update()

      assert errors_on(changeset) == %{
               name: ["has already been taken"]
             }
    end
  end
end
