defmodule Sig.HR.BenefitModelsTest do
  use Sig.DataCase

  alias Sig.HR.BenefitModels
  alias Sig.HR.BenefitModels.BenefitModel

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %BenefitModel{}} = BenefitModels.create_change()
    end
  end

  describe "update_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %BenefitModel{}} =
               BenefitModels.update_change(%BenefitModel{}, %{})

      assert %Ecto.Changeset{data: %BenefitModel{}} = BenefitModels.update_change(%BenefitModel{})
    end
  end

  describe "disable_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %BenefitModel{}} =
               BenefitModels.disable_change(%BenefitModel{}, %{})

      assert %Ecto.Changeset{data: %BenefitModel{}} =
               BenefitModels.disable_change(%BenefitModel{})
    end
  end

  describe "list/2" do
    test "lists benefit models from an org ordered by inserted_at" do
      org = insert(:org)

      insert(:employee_benefit_model, org: org, type: :transportation_voucher)
      insert(:employee_benefit_model, org: org, type: :health_insurance)

      insert(:employee_benefit_model, org: org, type: :meal_voucher, disabled_at: Date.utc_today())

      _to_ignore = insert(:employee_benefit_model)

      assert [
               %BenefitModel{type: :transportation_voucher},
               %BenefitModel{type: :health_insurance},
               %BenefitModel{type: :meal_voucher}
             ] = BenefitModels.list(org)
    end

    test "lists only enabled benefit models" do
      org = insert(:org)

      insert(:employee_benefit_model, org: org, type: :transportation_voucher)
      insert(:employee_benefit_model, org: org, type: :health_insurance)

      insert(:employee_benefit_model, org: org, type: :meal_voucher, disabled_at: Date.utc_today())

      assert [
               %BenefitModel{type: :transportation_voucher},
               %BenefitModel{type: :health_insurance}
             ] = BenefitModels.list(org, filter: :enabled)
    end

    test "when org has no benefit model" do
      org = insert(:org)

      _to_ignore = insert(:employee_benefit_model)

      assert BenefitModels.list(org) == []
    end
  end

  describe "get/2" do
    test "returns a benefit model" do
      org = insert(:org)
      %{id: id} = insert(:employee_benefit_model, org: org)

      assert %BenefitModel{id: ^id} = BenefitModels.get(org, id)
    end

    test "when benefit model belongs to another org" do
      org = insert(:org)

      another_org = insert(:org)
      %{id: id} = insert(:employee_benefit_model, org: another_org)

      assert BenefitModels.get(org, id) == nil
    end

    test "when benefit model doesn't exist" do
      org = insert(:org)

      assert BenefitModels.get(org, UUID.generate()) == nil
    end
  end

  describe "fetch/2" do
    test "returns a benefit model" do
      org = insert(:org)
      %{id: id} = insert(:employee_benefit_model, org: org)

      assert {:ok, %BenefitModel{id: ^id}} = BenefitModels.fetch(org, id)
    end

    test "when benefit model belongs to another org" do
      org = insert(:org)

      another_org = insert(:org)
      %{id: id} = insert(:employee_benefit_model, org: another_org)

      assert BenefitModels.fetch(org, id) == {:error, :not_found}
    end

    test "when benefit model doesn't exist" do
      org = insert(:org)

      assert BenefitModels.fetch(org, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "create/1" do
    test "creates a benefit model" do
      org = insert(:org)

      attrs = %{
        org_id: org.id,
        description: Faker.Lorem.sentence(),
        type: random_enum_value(:employee_benefit_type),
        amount: Enum.random(400_00..600_00),
        amount_date: Faker.Date.backward(100)
      }

      assert {:ok, %BenefitModel{id: id}} = BenefitModels.create(org, attrs)

      assert Repo.get_by(BenefitModel,
               id: id,
               org_id: org.id,
               description: attrs[:description],
               type: attrs[:type],
               amount: attrs[:amount],
               amount_date: attrs[:amount_date]
             )
    end

    test "returns changeset errors" do
      org = insert(:org)

      assert {:error, changeset} = BenefitModels.create(org, %{})

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               amount_date: ["can't be blank"],
               description: ["can't be blank"],
               type: ["can't be blank"]
             }
    end
  end

  describe "update/2" do
    test "updates a benefit model" do
      %{id: id} =
        model = insert(:employee_benefit_model, type: :meal_voucher, description: "Description")

      attrs = %{
        description: "New Description",
        type: :transportation_voucher
      }

      assert {:ok, %BenefitModel{id: ^id}} = BenefitModels.update(model, attrs)

      assert Repo.get_by(BenefitModel,
               id: model.id,
               org_id: model.org_id,
               description: attrs[:description],
               type: attrs[:type]
             )
    end

    test "returns changeset errors" do
      benefit_model = insert(:employee_benefit_model)

      attrs = %{
        description: nil,
        type: nil
      }

      assert {:error, changeset} = BenefitModels.update(benefit_model, attrs)

      assert errors_on(changeset) == %{
               description: ["can't be blank"],
               type: ["can't be blank"]
             }
    end
  end

  describe "update_amount/2" do
    test "updates a benefit model amount" do
      %{id: id} =
        model =
        insert(:employee_benefit_model, amount: 100_00, amount_date: Faker.Date.backward(100))

      attrs = %{
        amount: 200_00,
        amount_date: Date.utc_today()
      }

      assert {:ok, %BenefitModel{id: ^id}} = BenefitModels.update_amount(model, attrs)

      assert Repo.get_by(BenefitModel,
               id: model.id,
               org_id: model.org_id,
               amount: attrs[:amount],
               amount_date: attrs[:amount_date]
             )
    end

    test "returns changeset errors" do
      model =
        insert(:employee_benefit_model, amount: 100_00, amount_date: Faker.Date.backward(100))

      attrs = %{
        amount: nil,
        amount_date: nil
      }

      assert {:error, changeset} = BenefitModels.update_amount(model, attrs)

      assert errors_on(changeset) == %{
               amount: ["can't be blank"],
               amount_date: ["can't be blank"]
             }
    end
  end

  describe "disable/2" do
    test "disables a benefit model" do
      %{id: id} = model = insert(:employee_benefit_model, disabled_at: nil)

      attrs = %{disabled_at: Date.utc_today()}

      assert {:ok, %BenefitModel{id: ^id}} = BenefitModels.disable(model, attrs)

      assert Repo.get_by(BenefitModel,
               id: model.id,
               org_id: model.org_id,
               disabled_at: attrs[:disabled_at]
             )
    end

    test "returns changeset errors" do
      model = insert(:employee_benefit_model, disabled_at: nil)

      attrs = %{
        disabled_at: nil
      }

      assert {:error, changeset} = BenefitModels.disable(model, attrs)

      assert errors_on(changeset) == %{
               disabled_at: ["can't be blank"]
             }
    end
  end

  describe "enable/2" do
    test "enables a benefit model" do
      %{id: id} = model = insert(:employee_benefit_model, disabled_at: Date.utc_today())

      assert {:ok, %BenefitModel{id: ^id, disabled_at: nil}} = BenefitModels.enable(model)

      assert fetched_model =
               Repo.get_by(BenefitModel,
                 id: model.id,
                 org_id: model.org_id
               )

      assert fetched_model.disabled_at == nil
    end
  end

  describe "delete/1" do
    test "deletes a benefit model" do
      %{id: id} = model = insert(:employee_benefit_model)

      assert {:ok, %BenefitModel{id: ^id}} = BenefitModels.delete(model)

      refute Repo.get_by(BenefitModel, org_id: model.org_id, id: id)
    end

    test "when benefit model is associated to a benefit" do
      org = insert(:org)
      model = insert(:employee_benefit_model, org: org)
      insert(:employee_benefit_from_model, org: org, benefit_model: model)

      assert BenefitModels.delete(model) == {:error, "Existem benefícios associados ao modelo"}

      assert Repo.get_by(BenefitModel, org_id: org.id, id: model.id)
    end
  end

  describe "subscribe_to_benefit_models/1" do
    test "subscribes to org benefit_models topic" do
      org = insert(:org)
      topic = "org_id:" <> org.id <> ":benefit_models"

      assert BenefitModels.subscribe_to_benefit_models(org) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:new_benefit_model, :benefit_model})

      assert_receive {:new_benefit_model, :benefit_model}
    end
  end

  describe "broadcast_new_benefit_model/1" do
    test "broadcasts new benefit_models from an org" do
      org = insert(:org)
      benefit_model = insert(:employee_benefit_model, org: org)

      topic = "org_id:" <> org.id <> ":benefit_models"

      @endpoint.subscribe(topic)

      assert BenefitModels.broadcast_new_benefit_model(benefit_model) == :ok

      assert_receive {:new_benefit_model, received_benefit_model}

      assert received_benefit_model.id == benefit_model.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_updated_benefit_model/1" do
    test "broadcasts updated benefit_models from an org" do
      org = insert(:org)
      benefit_model = insert(:employee_benefit_model, org: org)

      topic = "org_id:" <> org.id <> ":benefit_models"

      @endpoint.subscribe(topic)

      assert BenefitModels.broadcast_updated_benefit_model(benefit_model) == :ok

      assert_receive {:updated_benefit_model, received_benefit_model}

      assert received_benefit_model.id == benefit_model.id

      @endpoint.unsubscribe(topic)
    end
  end

  describe "broadcast_deleted_benefit_model/1" do
    test "broadcasts updated benefit_models from an org" do
      org = insert(:org)
      benefit_model = insert(:employee_benefit_model, org: org)

      topic = "org_id:" <> org.id <> ":benefit_models"

      @endpoint.subscribe(topic)

      assert BenefitModels.broadcast_deleted_benefit_model(benefit_model) == :ok

      assert_receive {:deleted_benefit_model, received_benefit_model}

      assert received_benefit_model.id == benefit_model.id

      @endpoint.unsubscribe(topic)
    end
  end
end
