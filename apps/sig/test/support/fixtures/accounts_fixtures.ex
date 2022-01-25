defmodule Sig.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sig.Accounts` context.
  """

  import Sig.Factory

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "V@l1dUserPassword"

  def valid_user_attributes(attrs \\ %{})

  def valid_user_attributes(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> valid_user_attributes()
  end

  def valid_user_attributes(attrs) when is_map(attrs) do
    org = Map.get(attrs, :org) || insert(:org)
    individual = Map.get(attrs, :individual) || insert(:individual, org: org)

    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      org_id: org.id,
      individual_id: individual.entity_id
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Sig.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
