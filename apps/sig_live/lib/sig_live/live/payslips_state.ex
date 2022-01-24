defmodule SigLive.PayslipsState do
  @callback handle_filter_payslips(socket :: Socket.t()) :: Socket.t()
  @callback handle_apply_payslip_filters(socket :: Socket.t()) :: Socket.t()
  @callback sort_payslips(payslips :: List.t()) :: List.t()
  @callback handle_updated_payslip(payslip :: struct(), socket :: Socket.t()) ::
              {:atom, Socket.t()}
  @callback handle_empty_payslips(socket :: Socket.t()) :: Socket.t()

  defmacro __using__(_) do
    quote do
      @behaviour SigLive.PayslipsState

      alias Sig.HR
      alias Sig.Finance

      def handle_filter_payslips(socket), do: socket
      def handle_apply_payslip_filters(socket), do: socket
      def sort_payslips(payslips), do: payslips

      def handle_updated_payslip(%{id: id} = updated_payslip, socket) do
        %{payslips: payslips, selected_payslip: selected_payslip} = socket.assigns

        payslips =
          payslips
          |> Enum.map(fn
            %{id: ^id} -> updated_payslip
            payslip -> payslip
          end)
          |> sort_payslips()

        if selected_payslip != nil and selected_payslip.id == updated_payslip.id do
          {:noreply,
           socket
           |> assign(payslips: payslips, selected_payslip: updated_payslip)
           |> handle_apply_payslip_filters()}
        else
          {:noreply,
           socket
           |> assign(payslips: payslips)
           |> handle_apply_payslip_filters()}
        end
      end

      def handle_empty_payslips(socket) do
        socket
        |> assign(payslips: [])
        |> clear_selected_payslip()
        |> handle_apply_payslip_filters()
      end

      defoverridable handle_filter_payslips: 1
      defoverridable handle_apply_payslip_filters: 1
      defoverridable sort_payslips: 1
      defoverridable handle_updated_payslip: 2
      defoverridable handle_empty_payslips: 1

      @impl true
      def handle_info({:new_payslip, new_payslip}, socket) do
        %{payslips: payslips, selected_payslip: selected_payslip} = socket.assigns

        payslips = sort_payslips([new_payslip | payslips])

        if selected_payslip do
          {:noreply,
           socket
           |> assign(payslips: payslips)
           |> handle_apply_payslip_filters()}
        else
          subscribe_to_payslip_subscriptions(new_payslip)

          {:noreply,
           socket
           |> assign(payslips: payslips)
           |> assign_selected_payslip(new_payslip)
           |> handle_apply_payslip_filters()}
        end
      end

      @impl true
      def handle_info({:updated_payslip, updated_payslip}, socket) do
        handle_updated_payslip(updated_payslip, socket)
      end

      @impl true
      def handle_info({:deleted_payslip, deleted_payslip}, socket) do
        %{payslips: payslips, selected_payslip: selected_payslip} = socket.assigns

        payslips = Enum.reject(payslips, &(&1.id == deleted_payslip.id))

        with true <- selected_payslip.id == deleted_payslip.id,
             [_ | _] <- payslips do
          new_selected_payslip = List.first(payslips)

          unsubscribe_from_payslip_subscriptions(selected_payslip)
          subscribe_to_payslip_subscriptions(new_selected_payslip)

          {:noreply,
           socket
           |> assign(payslips: payslips)
           |> assign_selected_payslip(new_selected_payslip)
           |> handle_apply_payslip_filters()}
        else
          false ->
            {:noreply,
             socket
             |> assign(payslips: payslips)
             |> handle_apply_payslip_filters()}

          [] ->
            unsubscribe_from_payslip_subscriptions(selected_payslip)

            {:noreply, handle_empty_payslips(socket)}
        end
      end

      @impl true
      def handle_info({:updated_payslip_items, items}, socket) do
        {:noreply, assign(socket, selected_payslip_items: items)}
      end

      @impl true
      def handle_info({:updated_payables, :by_org, updated_payables}, socket) do
        %{
          selected_payslip: selected_payslip,
          selected_payslip_payables: selected_payslip_payables
        } = socket.assigns

        indexed_updated_payables = index_payables(updated_payables, selected_payslip.id)

        if indexed_updated_payables == %{} do
          {:noreply, socket}
        else
          updated_payables =
            Enum.map(selected_payslip_payables, fn payable ->
              case Map.get(indexed_updated_payables, payable.id) do
                nil -> payable
                updated_payable -> updated_payable
              end
            end)

          {:noreply, assign(socket, selected_payslip_payables: updated_payables)}
        end
      end

      @impl true
      def handle_info(
            {:updated_payables, {:by_payslip, payslip_id}, updated_payables},
            %{assigns: %{selected_payslip: %{id: payslip_id} = selected_payslip}} = socket
          ) do
        %{selected_payslip_payables: payables} = socket.assigns

        {:noreply, assign(socket, selected_payslip_payables: sort_payables(updated_payables))}
      end

      @impl true
      def handle_info({:updated_payables, _by, _updated_payables}, socket) do
        {:noreply, socket}
      end

      @impl true
      def handle_info({:deleted_payable, _payables}, socket) do
        {:noreply, socket}
      end

      defp index_payables(payables, selected_payslip_id) do
        Enum.reduce(payables, %{}, fn
          %{payslip: %Ecto.Association.NotLoaded{}}, acc ->
            acc

          %{payslip: %{id: ^selected_payslip_id}} = payable, acc ->
            Map.put(acc, payable.id, payable)

          _payable, acc ->
            acc
        end)
      end

      defp sort_payables(payables) do
        Enum.sort_by(payables, & &1.due_date, {:asc, Date})
      end

      defp subscribe_to_payslip_subscriptions(payslip) do
        HR.subscribe_to_payslip_items(payslip)
        Finance.subscribe_to_payables(payslip)
      end

      defp unsubscribe_from_payslip_subscriptions(payslip) do
        HR.unsubscribe_from_payslip_items(payslip)
        Finance.unsubscribe_from_payables(payslip)
      end

      defp assign_selected_payslip(socket, payslip) do
        assign(socket,
          selected_payslip: payslip,
          selected_payslip_items: list_payslip_items(payslip),
          selected_payslip_payables: list_payslip_payables(payslip)
        )
      end

      defp clear_selected_payslip(socket) do
        assign(socket,
          selected_payslip: nil,
          selected_payslip_items: [],
          selected_payslip_payables: []
        )
      end

      defp list_payslip_items(nil), do: []
      defp list_payslip_items(payslip), do: HR.list_items_by_payslip(payslip)

      defp list_payslip_payables(nil), do: []

      defp list_payslip_payables(payslip),
        do: Finance.list_payables_by(payslip, preload: [:financial_transaction])
    end
  end
end
