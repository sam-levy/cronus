defmodule Sig.HR.Payslips.ItemsTest do
  use Sig.DataCase

  alias Sig.HR.Payslips.Items
  alias Sig.HR.Payslips.Items.Item

  @endpoint SigLive.Endpoint

  describe "create_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Item{}} = Items.create_change()
      assert %Ecto.Changeset{data: %Item{}} = Items.create_change(%{})
    end
  end

  describe "create_outside_item_change/1" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Item{}} = Items.create_outside_item_change()
      assert %Ecto.Changeset{data: %Item{}} = Items.create_outside_item_change(%{})
    end
  end

  describe "update_amount_change/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{data: %Item{}} = Items.update_amount_change(%Item{})
      assert %Ecto.Changeset{data: %Item{}} = Items.update_amount_change(%Item{}, %{})
    end
  end

  describe "list_by_payslip/1" do
    test "lists payslip items by payslip ordered by code" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA"
        )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        description: "Complemento Salário",
        entry_type: :credit
      )

      insert(:payslip_item, org: org, payslip: payslip, category: health_insurance_category)
      insert(:payslip_item, org: org, payslip: payslip, category: salary_category)

      assert [
               %Item{code: "1", description: "SALÁRIO", entry_type: :credit},
               %Item{code: "115", description: "ASSISTÊNCIA MÉDICA", entry_type: :debit},
               %Item{code: nil, description: "Complemento Salário", entry_type: :credit}
             ] = Items.list_by_payslip(payslip)
    end

    test "payslip has no items" do
      payslip = insert(:payslip)

      assert Items.list_by_payslip(payslip) == []
    end
  end

  describe "get/2" do
    test "returns a payslip_item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      %{id: id} = insert(:payslip_item, org: org, payslip: payslip, category: category)

      assert %Item{id: ^id, code: "1", description: "SALÁRIO", entry_type: :credit} =
               Items.get(payslip, id)
    end

    test "returns an outside_item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      %{id: id} =
        insert(:payslip_outside_item,
          org: org,
          payslip: payslip,
          description: "Complemento Salário",
          entry_type: :credit
        )

      assert %Item{id: ^id, code: nil, description: "Complemento Salário", entry_type: :credit} =
               Items.get(payslip, id)
    end

    test "when item belongs to other payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)
      other_payslip = insert(:payslip, org: org)

      %{id: id} =
        insert(:payslip_outside_item,
          org: org,
          payslip: other_payslip,
          description: "Complemento Salário",
          entry_type: :credit
        )

      assert Items.get(payslip, id) == nil
    end

    test "when item doesn't exist" do
      payslip = insert(:payslip)

      assert Items.get(payslip, UUID.generate()) == nil
    end
  end

  describe "fetch/2" do
    test "returns a payslip_item" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      category =
        insert(:payslip_category, org: org, code: "1", entry_type: :credit, description: "SALÁRIO")

      %{id: id} = insert(:payslip_item, org: org, payslip: payslip, category: category)

      assert {:ok, %Item{id: ^id, code: "1", description: "SALÁRIO", entry_type: :credit}} =
               Items.fetch(payslip, id)
    end

    test "when item doesn't exist" do
      payslip = insert(:payslip)

      assert Items.fetch(payslip, UUID.generate()) == {:error, :not_found}
    end
  end

  describe "sum_payments_in_advance_items_by_payslip/1" do
    test "sums the amounts of payments in advance items" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category,
          org: org,
          code: "1",
          entry_type: :credit,
          description: "SALÁRIO",
          amount: 1_000_00
        )

      insert(:payslip_item, org: org, payslip: payslip, category: salary_category)

      salary_advance_category =
        insert(:payslip_category,
          org: org,
          code: "12",
          entry_type: :debit,
          description: "ADIANTAMENTO ANTERIOR"
        )

      insert(:payslip_item,
        org: org,
        payslip: payslip,
        category: salary_advance_category,
        amount: 400_00,
        is_payment_advance: true
      )

      insert(:payslip_outside_item,
        org: org,
        payslip: payslip,
        description: "Adiantamento",
        entry_type: :debit,
        amount: 200_00,
        is_payment_advance: true
      )

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA",
          amount: 300_00
        )

      insert(:payslip_item, org: org, payslip: payslip, category: health_insurance_category)

      assert Items.sum_payments_in_advance_items_by_payslip(payslip) == %Money{
               amount: 600_00,
               currency: :BRL
             }
    end

    test "when payslip has no payments in advance" do
      org = insert(:org)
      payslip = insert(:payslip, org: org)

      salary_category =
        insert(:payslip_category,
          org: org,
          code: "1",
          entry_type: :credit,
          description: "SALÁRIO",
          amount: 1_000_00
        )

      insert(:payslip_item, org: org, payslip: payslip, category: salary_category)

      health_insurance_category =
        insert(:payslip_category,
          org: org,
          code: "115",
          entry_type: :debit,
          description: "ASSISTÊNCIA MÉDICA",
          amount: 300_00
        )

      insert(:payslip_item, org: org, payslip: payslip, category: health_insurance_category)

      assert Items.sum_payments_in_advance_items_by_payslip(payslip) == %Money{
               amount: 0,
               currency: :BRL
             }
    end
  end

  describe "subscribe_to_payslip_items/1" do
    test "subscribes to payslip items topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id <> ":items"

      assert Items.subscribe_to_payslip_items(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payslip_items, :items})

      assert_receive {:updated_payslip_items, :items}
    end
  end

  describe "unsubscribe_from_payslip_items/1" do
    test "subscribes to payslip items topic" do
      payslip = insert(:payslip)
      topic = "payslip_id:" <> payslip.id <> ":items"

      @endpoint.subscribe(topic)

      assert Items.unsubscribe_from_payslip_items(payslip) == :ok

      Phoenix.PubSub.broadcast(Sig.PubSub, topic, {:updated_payslip_items, :items})

      refute_receive {:updated_payslip_items, :items}
    end
  end

  describe "broadcast_payslip_items/1" do
    test "broadcasts items from a payslip" do
      org = insert(:org)
      payslip = insert(:payslip, org: org, start_date: ~D[2021-01-01])

      insert(:payslip_item, org: org, payslip: payslip)
      insert(:payslip_item, org: org, payslip: payslip)
      insert(:payslip_outside_item, org: org, payslip: payslip)

      another_org = insert(:org)
      another_payslip = insert(:payslip, org: another_org, start_date: ~D[2021-02-01])

      _to_ignore = insert(:payslip_item, org: another_org, payslip: another_payslip)

      topic = "payslip_id:" <> payslip.id <> ":items"

      @endpoint.subscribe(topic)

      assert Items.broadcast_payslip_items(payslip) == :ok

      assert_receive {:updated_payslip_items, received_payslip_items}

      assert Enum.count(received_payslip_items) == 3

      Enum.each(received_payslip_items, fn payslip_item ->
        assert payslip_item.org_id == org.id
        assert payslip_item.payslip_id == payslip.id
      end)

      @endpoint.unsubscribe(topic)
    end
  end
end
