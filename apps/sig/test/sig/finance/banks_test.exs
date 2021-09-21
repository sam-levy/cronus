defmodule Sig.Finance.BanksTest do
  use Sig.DataCase

  alias Sig.Finance.Banks
  alias Sig.Finance.Banks.Bank

  describe "list_banks/0" do
    test "returns all banks" do
      assert [%Bank{} | _banks] = Banks.list_banks()
    end
  end

  describe "fetch_bank_name/0" do
    test "returns the bank name" do
      assert Banks.fetch_bank_name("001") == {:ok, "Banco do Brasil S.A."}
    end

    test "invalid routing number" do
      assert Banks.fetch_bank_name("invalid") == {:error, :not_found}
    end
  end

  describe "valid_routing_number/0" do
    test "when valid" do
      assert Banks.valid_routing_number?("001")
    end

    test "when invalid" do
      refute Banks.valid_routing_number?("invalid")
    end
  end
end
