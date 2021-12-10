defmodule Sig.HR.PayslipTemplatesTest do
  use Sig.DataCase

  alias Sig.HR.PayslipTemplates
  alias Sig.HR.PayslipTemplates.PayslipTemplate
  alias Sig.HR.PayslipTemplates.PayslipTemplateItems.PayslipTemplateItem

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %PayslipTemplate{}} = PayslipTemplates.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %PayslipTemplate{}} =
               PayslipTemplates.update_change(%PayslipTemplate{}, %{})

      assert %Ecto.Changeset{data: %PayslipTemplate{}} =
               PayslipTemplates.update_change(%PayslipTemplate{})
    end
  end

  describe "list/1" do
    test "lists payslip templates from an organization ordered by name" do
      %{id: org_id} = org = insert(:org)

      insert(:payslip_template, org: org, name: "Template B")
      insert(:payslip_template, org: org, name: "Template A")
      _to_ignore = insert(:payslip_template)

      assert [
               %PayslipTemplate{org_id: ^org_id, name: "Template A"},
               %PayslipTemplate{org_id: ^org_id, name: "Template B"}
             ] = PayslipTemplates.list(org)
    end

    test "when org has no payslip templates" do
      org = insert(:org)

      assert PayslipTemplates.list(org) == []
    end
  end

  describe "create/2" do
    test "creates a payslip template" do
      org = insert(:org)

      attrs = %{
        name: Faker.Commerce.department()
      }

      assert {:ok, %PayslipTemplate{id: id}} = PayslipTemplates.create(org, attrs)

      assert Repo.get_by(PayslipTemplate,
               id: id,
               org_id: org.id,
               name: attrs[:name]
             )
    end

    test "returns changeset errors" do
      org = insert(:org)

      assert {:error, changeset} = PayslipTemplates.create(org, %{})

      assert errors_on(changeset) == %{
               name: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a payslip template" do
      payslip_template = insert(:payslip_template)

      attrs = %{name: "New Description"}

      assert {:ok, _return} = PayslipTemplates.update(payslip_template, attrs)

      assert Repo.get_by(PayslipTemplate,
               name: attrs[:name]
             )
    end

    test "returns changeset errors" do
      payslip_template = insert(:payslip_template)

      attrs = %{name: nil}

      assert {:error, changeset} = PayslipTemplates.update(payslip_template, attrs)

      assert errors_on(changeset) == %{
               name: ["can't be blank"]
             }
    end
  end

  describe "get/3" do
    test "returns a payslip template" do
      org = insert(:org)
      %{id: id} = insert(:payslip_template, org: org)

      assert %PayslipTemplate{id: ^id} = PayslipTemplates.get(org, id)
    end

    test "when payslip template doesn't belongs to org" do
      org = insert(:org)
      %{id: id} = insert(:payslip_template)

      assert PayslipTemplates.get(org, id) == nil
    end

    test "when payslip template doesn't exist" do
      org = insert(:org)

      assert PayslipTemplates.get(org, UUID.generate()) == nil
    end
  end

  describe "delete/1" do
    test "deletes a payslip template and its payslip items" do
      org = insert(:org)
      %{id: payslip_template_id} = payslip_template = insert(:payslip_template, org: org)

      insert_list(2, :payslip_template_item,
        org: org,
        payslip_template: payslip_template
      )

      assert {:ok, %PayslipTemplate{id: ^payslip_template_id}} =
               PayslipTemplates.delete(payslip_template)

      refute Repo.get_by(PayslipTemplate,
               org_id: org.id,
               id: payslip_template_id
             )

      refute Repo.get_by(PayslipTemplateItem,
               org_id: org.id,
               payslip_template_id: payslip_template_id
             )
    end
  end

  describe "subscribe_to_payslip_templates/1" do
    test "subscribes to the payslip templates topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":payslip_templates"

      assert PayslipTemplates.subscribe_to_payslip_templates(org) == :ok

      Phoenix.PubSub.broadcast(
        Sig.PubSub,
        topic,
        {:new_payslip_template, :payslip_template}
      )

      assert_receive {:new_payslip_template, :payslip_template}
    end
  end

  describe "broadcast_new_payslip_template/1" do
    test "broadcasts a new payslip template from an org" do
      org = insert(:org)

      payslip_template = insert(:payslip_template, org: org)

      topic = "org_id:" <> org.id <> ":payslip_templates"

      @endpoint.subscribe(topic)

      assert PayslipTemplates.broadcast_new_payslip_template(payslip_template) == :ok

      assert_receive {:new_payslip_template, received_payslip_template}

      assert received_payslip_template.id == payslip_template.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_payslip_template/1" do
    test "broadcasts an updated payslip template from an org" do
      org = insert(:org)

      payslip_template = insert(:payslip_template, org: org)

      topic = "org_id:" <> org.id <> ":payslip_templates"

      @endpoint.subscribe(topic)

      assert PayslipTemplates.broadcast_updated_payslip_template(payslip_template) == :ok

      assert_receive {:updated_payslip_template, received_payslip_template}

      assert received_payslip_template.id == payslip_template.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_payslip_template/1" do
    test "broadcasts a deleted payslip template from an org" do
      org = insert(:org)

      payslip_template = insert(:payslip_template, org: org)

      topic = "org_id:" <> org.id <> ":payslip_templates"

      @endpoint.subscribe(topic)

      assert PayslipTemplates.broadcast_deleted_payslip_template(payslip_template) == :ok

      assert_receive {:deleted_payslip_template, received_payslip_template}

      assert received_payslip_template.id == payslip_template.id

      @endpoint.unsubscribe(topic)
    end
  end
end
