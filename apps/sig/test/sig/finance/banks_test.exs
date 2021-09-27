defmodule Sig.Finance.BanksTest do
  use Sig.DataCase

  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Bank

  describe "list_banks/0" do
    test "returns all banks" do
      assert [%Bank{} | _banks] = Banks.list_banks()
    end
  end

  describe "fetch_bank/1" do
    test "returns a bank" do
      assert {:ok, %Bank{name: "Banco do Brasil S.A."}} = Banks.fetch_bank("001")
    end

    test "invalid routing number" do
      assert Banks.fetch_bank("invalid") == {:error, :not_found}
    end
  end

  describe "valid_routing_number/1" do
    test "when valid" do
      assert Banks.valid_routing_number?("001")
    end

    test "when invalid" do
      refute Banks.valid_routing_number?("invalid")
    end
  end
end
