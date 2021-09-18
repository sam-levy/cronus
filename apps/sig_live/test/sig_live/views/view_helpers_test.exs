defmodule SigLive.ViewHelpersTest do
  use Sig.DataCase

	alias BrazilianDocuments.Types.CPF

  alias SigLive.ViewHelpers

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
end
