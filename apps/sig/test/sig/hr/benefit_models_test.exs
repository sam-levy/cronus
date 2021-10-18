defmodule Sig.HR.BenefitModelsTest do
  use Sig.DataCase

  alias Sig.HR.BenefitModels
  alias Sig.HR.BenefitModels.BenefitModel

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
end
