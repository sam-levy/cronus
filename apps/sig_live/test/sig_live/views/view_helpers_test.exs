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

  describe "format_bank_account/1" do
    test "when account has a name" do
      account =
        insert(:bank_account,
          routing_number: "104",
          branch_number: "321",
          number: "654",
          name: "CEF Loja Tal"
        )

      assert ViewHelpers.format_bank_account(account) ==
               "CEF Loja Tal - 104 - Caixa Econômica Federal - Ag: 321 - Conta: 654"
    end

    test "when account name is nil" do
      account = insert(:bank_account, routing_number: "104", branch_number: "321", number: "654")

      assert ViewHelpers.format_bank_account(account) ==
               "104 - Caixa Econômica Federal - Ag: 321 - Conta: 654"
    end
  end

  describe "bank_accounts_for_select/1" do
    test "returns a map of bank accounts and ids" do
      account_1 =
        insert(:bank_account, routing_number: "001", branch_number: "123", number: "456")

      account_2 =
        insert(:bank_account,
          routing_number: "104",
          branch_number: "321",
          number: "654",
          name: "CEF Loja Tal"
        )

      assert ViewHelpers.bank_accounts_for_select([account_1, account_2]) == %{
               "001 - Banco do Brasil S.A. - Ag: 123 - Conta: 456" => account_1.id,
               "CEF Loja Tal - 104 - Caixa Econômica Federal - Ag: 321 - Conta: 654" =>
                 account_2.id
             }
    end
  end

  describe "enum_for_select/1" do
    defmodule TestEnum do
      def __valid_values__, do: [:first_item, "first_item", :second_item, "second_item"]
    end

    test "returns a map of enums with strings keys" do
      assert ViewHelpers.enum_for_select(TestEnum) == %{
               "First Item" => "first_item",
               "Second Item" => "second_item"
             }
    end
  end

  describe "list_for_select/1" do
    test "returns a map with the item wihtout low dashes as keys" do
      list = [:first_item, :second_item]

      assert ViewHelpers.list_for_select(list) == %{
               "First Item" => "first_item",
               "Second Item" => "second_item"
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

  describe "format_date/2" do
    test "stringfy a date" do
      assert ViewHelpers.format_date(~D[2010-01-01]) == "01/01/10"
      assert ViewHelpers.format_date(~D[2010-01-01], "%A, %b %d") == "Friday, Jan 01"
      assert ViewHelpers.format_date(nil) == ""
    end
  end

  describe "fformat_month/2" do
    test "formats month" do
      assert ViewHelpers.format_month(~D[2010-01-01]) == "Janeiro 2010"
      assert ViewHelpers.format_month(~D[2020-06-15]) == "Junho 2020"
    end
  end

  describe "format_type/1" do
    assert ViewHelpers.format_type(:health_insurance) == "health insurance"
    assert ViewHelpers.format_type("health_insurance") == "health insurance"
  end

  describe "capitalize_type/1" do
    assert ViewHelpers.capitalize_type(:health_insurance) == "Health Insurance"
    assert ViewHelpers.capitalize_type("health_insurance") == "Health Insurance"
  end

  describe "companies_for_select/1" do
    test "returns a map with companies registration or trade name as keys and entity ids as values" do
      %{entity_id: acme_id} = acme = insert(:virtual_company, trade_name: "Acme LLC")

      %{entity_id: dm_id} =
        dunder_mifflin = insert(:company, registration_name: "Dunder Mifflin LLC")

      assert %{"Acme LLC" => ^acme_id, "Dunder Mifflin LLC" => ^dm_id} =
               ViewHelpers.companies_for_select([acme, dunder_mifflin])
    end

    test "when list is empty" do
      assert ViewHelpers.companies_for_select([]) == %{}
    end
  end

  describe "id_by_name_for_select/1" do
    test "returns a map with names as keys and ids as values" do
      %{id: cooker_id} = cooker = insert(:org_position, name: "cooker")
      %{id: clerk_id} = clerk = insert(:org_position, name: "clerk")

      assert %{"cooker" => ^cooker_id, "clerk" => ^clerk_id} =
               ViewHelpers.id_by_name_for_select([cooker, clerk])
    end

    test "when list is empty" do
      assert ViewHelpers.id_by_name_for_select([]) == %{}
    end
  end

  describe "format_amount/1" do
    test "formats amount" do
      assert ViewHelpers.format_amount(%Ecto.Changeset{
               changes: %{amount: %Money{amount: 2_000_00}}
             }) == "2.000,00"

      assert ViewHelpers.format_amount(%Money{amount: 1_500_00}) == "1.500,00"
      assert ViewHelpers.format_amount(nil) == ""
    end
  end

  describe "payslip_categories_for_select/1" do
    test "returns a maps of categories formated for select" do
      category_1 =
        insert(:payslip_category, code: "1", description: "SALÁRIO", entry_type: :credit)

      category_2 =
        insert(:payslip_category,
          code: "109",
          description: "DESC. VALE TRANSPORTE",
          entry_type: :debit
        )

      assert ViewHelpers.payslip_categories_for_select([category_1, category_2]) == %{
               "1 - SALÁRIO - Crédito" => category_1.id,
               "109 - DESC. VALE TRANSPORTE - Débito" => category_2.id
             }
    end

    test "empty list" do
      assert ViewHelpers.payslip_categories_for_select([]) == %{}
    end
  end
end
