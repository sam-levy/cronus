defmodule Sig.Factories.PayableFactory do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Sig.Finance.Payables.Payable
      alias Sig.Finance.Payables.Payable.PayableTarget

      def factory(:payable, attrs) do
        due_date = Keyword.get(attrs, :due_date) || Date.utc_today()

        %Payable{
          org: build(:org),
          due_date: due_date,
          reference_date: Date.beginning_of_month(due_date),
          amount: Enum.random(100_00..5_000_00) |> Money.new(),
          description: Faker.Lorem.sentence(),
          target: random_enum_value(:payable_target),
          is_fulfilled: false
        }
      end

      def factory(:payable_cash, attrs) do
        payable = build(:payable, attrs)

        %Payable{payable | method: :cash}
      end

      def factory(:payable_check, attrs) do
        org = Keyword.get(attrs, :org) || build(:org)
        payable = build(:payable, Keyword.put_new(attrs, :org, org))

        %Payable{
          payable
          | method: :check,
            check_number: random_string_number(),
            check_bank_account: build(:bank_account, org: org)
        }
      end

      def factory(:payable_billet, attrs) do
        payable = build(:payable, attrs)

        %Payable{
          payable
          | method: :billet,
            billet_barcode: random_string_number()
        }
      end

      def factory(:payable_bank_transfer, attrs) do
        org = Keyword.get(attrs, :org) || build(:org)
        payable = build(:payable, Keyword.put_new(attrs, :org, org))

        %Payable{
          payable
          | method: :bank_transfer,
            credit_bank_account: build(:bank_account, org: org)
        }
      end

      def random_enum_value(:payable_target) do
        random_enum_value(PayableTarget)
      end
    end
  end
end
