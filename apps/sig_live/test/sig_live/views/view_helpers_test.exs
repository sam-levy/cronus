defmodule SigLive.ViewHelpersTest do
  use Sig.DataCase

  alias BrazilianDocuments.Types.CPF

  alias Sig.Finance.Banks.Bank
  alias SigLive.ViewHelpers

  describe "bank_name/1" do
    test "returns the bank name" do
      assert ViewHelpers.bank_name("001") == "Banco do Brasil S.A."
      assert ViewHelpers.bank_name("invalid") == ""
    end
  end

  describe "bank_name_with_number/1" do
    test "returns the bank name with its routing number" do
      assert ViewHelpers.bank_name_with_number("001") == "001 - Banco do Brasil S.A."
      assert ViewHelpers.bank_name_with_number("invalid") == ""

      bank = %Bank{name: "Banco do Brasil S.A.", routing_number: "001"}

      assert ViewHelpers.bank_name_with_number(bank) == "001 - Banco do Brasil S.A."
    end
  end

  describe "banks_for_select/1" do
    test "returns a map of bank names and routing numbers" do
      banks = [
        %Bank{name: "Banco do Brasil S.A.", routing_number: "001"},
        %Bank{name: "Caixa Econômica Federal", routing_number: "104"}
      ]

      assert ViewHelpers.banks_for_select(banks) == %{
               "001 - Banco do Brasil S.A." => "001",
               "104 - Caixa Econômica Federal" => "104"
             }
    end
  end

  describe "bank_for_select/1" do
    test "returns a map of bank names and routing numbers" do
      assert ViewHelpers.bank_for_select("001") == %{
               "001 - Banco do Brasil S.A." => "001"
             }
    end
  end

  describe "bank_accounts_for_select/1" do
    test "returns a map of bank accounts and ids" do
      account_1 =
        insert(:bank_account, routing_number: "001", branch_number: "123", number: "456")

      account_2 =
        insert(:bank_account, routing_number: "104", branch_number: "321", number: "654")

      assert ViewHelpers.bank_accounts_for_select([account_1, account_2]) == %{
               "001 - Banco do Brasil S.A. - Ag: 123 - Conta: 456" => account_1.id,
               "104 - Caixa Econômica Federal - Ag: 321 - Conta: 654" => account_2.id
             }
    end
  end

  describe "enum_for_select/1" do
    defmodule TestEnum do
      def __valid_values__, do: [:first_item, "first_item", :second_item, "second_item"]
    end

    test "returns a map of enums with strings keys" do
      assert ViewHelpers.enum_for_select(TestEnum) == %{
               "first item" => "first_item",
               "second item" => "second_item"
             }
    end
  end

  describe "format_cpf/1" do
    test "returns a formatted cpf for a CPF struct" do
      assert ViewHelpers.format_cpf(%CPF{number: "55567307098"}) == "555.673.070-98"
    end

    test "returns a formatted cpf for a CPF string" do
      assert ViewHelpers.format_cpf("76706017019") == "767.060.170-19"
      assert ViewHelpers.format_cpf("649.434.820-31") == "649.434.820-31"
    end

    test "wrong cpf" do
      assert ViewHelpers.format_cpf("wrong") == ""
    end
  end

  describe "format_document/1" do
    test "returns a formatted CPF or CNPJ" do
      assert ViewHelpers.format_document("44316760076") == "443.167.600-76"
      assert ViewHelpers.format_document("90667621000116") == "90.667.621/0001-16"
      assert ViewHelpers.format_document("wrong") == "wrong"
      assert ViewHelpers.format_document(nil) == ""
    end
  end
end
