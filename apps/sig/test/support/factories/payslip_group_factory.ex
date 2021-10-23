defmodule Sig.Factories.PayslipGroupFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.HR.Payslips.Groups.Group
      alias Sig.HR.Payslips.PayslipGroupType

      def factory(:payslip_group, attrs) do
        %Group{
          org: insert(:org),
          date: Faker.Date.backward(1000) |> Date.beginning_of_month(),
          type: random_enum_value(:payslip_group_type)
        }
      end

      def random_enum_value(:payslip_group_type) do
        random_enum_value(PayslipGroupType)
      end
    end
  end
end
