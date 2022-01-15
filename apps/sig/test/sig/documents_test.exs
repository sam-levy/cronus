defmodule Sig.DocumentsTest do
  use Sig.DataCase, async: true

  alias Sig.Documents

  describe "format_cpf/1" do
    test "formats CPF with odd separation" do
      assert Documents.format_cpf("11140442023") == {:ok, "111.404.420-23"}
      assert Documents.format_cpf(" 111.404.420-23  ") == {:ok, "111.404.420-23"}
      assert Documents.format_cpf("111 404 420 23  ") == {:ok, "111.404.420-23"}
      assert Documents.format_cpf("111.404.42023") == {:ok, "111.404.420-23"}
    end
  end

  describe "format_cnpj/1" do
    test "formats CNPJ with odd separation" do
      assert Documents.format_cnpj("39297367000154") == {:ok, "39.297.367/0001-54"}
      assert Documents.format_cnpj("  39.297.367/0001-54  ") == {:ok, "39.297.367/0001-54"}
      assert Documents.format_cnpj("  39 297 367 0001 54  ") == {:ok, "39.297.367/0001-54"}
      assert Documents.format_cnpj("39.297367/ 0001 -54  ") == {:ok, "39.297.367/0001-54"}
    end
  end

  describe "format_document/1" do
    test "formats CPF or CNPJ with odd separation" do
      assert Documents.format_document("11140442023") == {:cpf, "111.404.420-23"}
      assert Documents.format_document(" 111.404.420-23  ") == {:cpf, "111.404.420-23"}
      assert Documents.format_document("111 404 420 23  ") == {:cpf, "111.404.420-23"}
      assert Documents.format_document("111.404.42023") == {:cpf, "111.404.420-23"}

      assert Documents.format_document("39297367000154") == {:cnpj, "39.297.367/0001-54"}
      assert Documents.format_document("  39.297.367/0001-54  ") == {:cnpj, "39.297.367/0001-54"}
      assert Documents.format_document("  39 297 367 0001 54  ") == {:cnpj, "39.297.367/0001-54"}
      assert Documents.format_document("39.297367/ 0001 -54  ") == {:cnpj, "39.297.367/0001-54"}
    end
  end
end
