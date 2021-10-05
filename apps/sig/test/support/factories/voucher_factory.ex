defmodule Sig.Factories.VoucherFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Registrations.Vouchers.Voucher
      alias Sig.HR.Registrations.Vouchers.Voucher.VoucherType

      def factory(:employee_voucher, attrs) do
        org = Keyword.get(attrs, :org, insert(:org))
        registration = Keyword.get(attrs, :registration, insert(:employee_registration, org: org))

        %Voucher{
          org: org,
          registration: registration,
          type: random_enum_value(:employee_voucher_type),
          amount: Enum.random(400_00..600_00),
          start_date: Faker.Date.backward(100)
        }
      end

      def random_enum_value(:employee_voucher_type) do
        random_enum_value(VoucherType)
      end
    end
  end
end
