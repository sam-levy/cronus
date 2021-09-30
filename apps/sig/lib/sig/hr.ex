defmodule Sig.HR do
  alias Sig.HR.Registrations

  defdelegate create_registration_change(attrs), to: Registrations, as: :create_change

  defdelegate update_registration_change(registration, attrs),
    to: Registrations,
    as: :update_change

  defdelegate resignation_registration_change(registration, attrs),
    to: Registrations,
    as: :resignation_change

  defdelegate create_registration(org, individual, attrs), to: Registrations, as: :create
  defdelegate update_registration(individual, attrs), to: Registrations, as: :update

  defdelegate list_registrations_by_individual(individual),
    to: Registrations,
    as: :list_by_individual

  defdelegate fetch_registration(individual, id), to: Registrations, as: :fetch
  defdelegate subscribe_to_individual_registrations(individual), to: Registrations
  defdelegate broadcast_individual_registrations(indiviual), to: Registrations
end
