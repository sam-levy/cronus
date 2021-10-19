defmodule Sig.HR.BenefitModelsTest do
  use Sig.DataCase

  alias Sig.HR.BenefitModels
  alias Sig.HR.BenefitModels.BenefitModel

  describe "list/2" do
    test "lists benefit models from an org ordered by inserted_at" do
      org = insert(:org)

      insert(:employee_benefit_model, org: org, type: :transportation_voucher)
      insert(:employee_benefit_model, org: org, type: :health_insurance)

      insert(:employee_benefit_model, org: org, type: :meal_voucher, disabled_at: Date.utc_today())

      _to_ignore = insert(:employee_benefit_model)

      assert [
               %BenefitModel{type: :transportation_voucher},
               %BenefitModel{type: :health_insurance}
             ] = BenefitModels.list(org)
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

    test "when benefit model is inactive" do
      org = insert(:org)
      %{id: id} = insert(:employee_benefit_model, org: org, disabled_at: Date.utc_today())

      assert BenefitModels.get(org, id) == nil
    end

    test "when benefit model doesn't exist" do
      org = insert(:org)

      assert BenefitModels.get(org, UUID.generate()) == nil
    end
  end
end
