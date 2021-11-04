defmodule Sig.Finance.PayablesTest do
  use Sig.DataCase

  alias Sig.Finance.Payables
  alias Sig.Finance.Payables.Payable

  describe "authorize/2" do
    test "assign a authorized_by_id to a payable" do
      org = insert(:org)
      %{id: id} = payable = insert(:payable_cash, org: org)
      user = insert(:user, org: org)

      attrs = %{authorized_by_id: user.id}

      assert {:ok, %Payable{id: ^id}} = Payables.authorize(payable, attrs)

      assert Repo.get_by(Payable,
               org_id: org.id,
               id: id,
               authorized_by_id: user.id
             )
    end
  end

  describe "unauthorize/2" do
    test "removes a authorized_by_id from a payable" do
      org = insert(:org)
      user = insert(:user, org: org)
      %{id: id} = payable = insert(:payable_cash, org: org, authorized_by_id: user.id)

      assert {:ok, %Payable{id: ^id}} = Payables.unauthorize(payable)

      assert persisted_payable =
               Repo.get_by(Payable,
                 org_id: org.id,
                 id: id
               )

      assert persisted_payable.authorized_by_id == nil
    end

    test "when authorized_by_id is already nil" do
      %{id: id} = payable = insert(:payable_cash, authorized_by_id: nil)

      assert {:ok, %Payable{id: ^id}} = Payables.unauthorize(payable)

      assert persisted_payable =
               Repo.get_by(Payable,
                 org_id: payable.org_id,
                 id: id
               )

      assert persisted_payable.authorized_by_id == nil
    end
  end
end
