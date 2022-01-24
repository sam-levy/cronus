defmodule SigLive.AccountsPayable.FinancialTransactions.ClearForm do
  use SigLive, :surface_live_component

  alias Sig.Finance

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    DateInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop financial_transaction, :struct, required: true

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{financial_transaction: financial_transaction} = assigns

    socket =
      socket
      |> assign(assigns)
      |> assign(changeset: Finance.financial_transaction_update_change(financial_transaction))

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"financial_transaction" => params}, socket) do
    %{financial_transaction: financial_transaction} = socket.assigns

    with changeset <- Finance.financial_transaction_update_change(financial_transaction, params),
         {:ok, _attrs} <- apply_action(changeset, :update),
         {:ok, financial_transaction} <-
           Finance.clear_financial_transaction(financial_transaction, changeset.changes) do
      Finance.broadcast_updated_financial_transaction(financial_transaction)
      flash_info("Transação Liquidada")
      socket.assigns.close_fun.()

      {:noreply, socket}
    else
      {:error, changeset} when is_struct(changeset) ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, message} ->
        {:noreply, assign(socket, message: message)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Liquidar Transação" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:clearing_date} class="form-field">
          <Label class="form-label">Data de Liquidação</Label>
          <DateInput class="form-input"/>
          <ErrorTag class="form-error-tag"/>
        </Field>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."}/>
        </div>
      </Form>
    </Modal>
    """
  end
end
