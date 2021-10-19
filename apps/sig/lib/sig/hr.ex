defmodule Sig.HR do
  alias Sig.HR.Registrations
  alias Sig.HR.Registrations.Salaries
  alias Sig.HR.Registrations.Vouchers
  alias Sig.HR.Registrations.Warnings

  defdelegate create_registration_change(attrs \\ %{}), to: Registrations, as: :create_change

  defdelegate update_registration_change(registration, attrs \\ %{}),
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

  defdelegate get_registration(individual, id), to: Registrations, as: :get
  defdelegate subscribe_to_individual_registrations(individual), to: Registrations
  defdelegate broadcast_individual_registrations(indiviual), to: Registrations

  defdelegate list_salaries_by_registration(registration), to: Salaries, as: :list_by_registration
  defdelegate create_salary(registration, attrs), to: Salaries, as: :create
  defdelegate subscribe_to_registration_salaries(registration), to: Salaries
  defdelegate broadcast_registration_salaries(registration), to: Salaries
  defdelegate create_salary_change(attrs \\ %{}), to: Salaries, as: :create_change

  defdelegate list_vouchers_by_registration(registration), to: Vouchers, as: :list_by_registration
  defdelegate list_voucher_types, to: Vouchers
  defdelegate get_voucher(registration, id), to: Vouchers, as: :get
  defdelegate create_voucher(registration, attrs), to: Vouchers, as: :create
  defdelegate update_voucher(voucher, attrs), to: Vouchers, as: :update
  defdelegate subscribe_to_registration_vouchers(registration), to: Vouchers
  defdelegate broadcast_registration_vouchers(registration), to: Vouchers
  defdelegate create_voucher_change(attrs \\ %{}), to: Vouchers, as: :create_change
  defdelegate update_voucher_change(voucher, attrs \\ %{}), to: Vouchers, as: :update_change

  defdelegate list_warnings_by_registration(registration), to: Warnings, as: :list_by_registration
  defdelegate get_warning(registration, id), to: Warnings, as: :get
  defdelegate create_warning(registration, attrs), to: Warnings, as: :create
  defdelegate update_warning(warning, attrs), to: Warnings, as: :update
  defdelegate subscribe_to_registration_warnings(registration), to: Warnings
  defdelegate broadcast_registration_warnings(registration), to: Warnings
  defdelegate create_warning_change(attrs \\ %{}), to: Warnings, as: :create_change
  defdelegate update_warning_change(warning, attrs \\ %{}), to: Warnings, as: :update_change
end
