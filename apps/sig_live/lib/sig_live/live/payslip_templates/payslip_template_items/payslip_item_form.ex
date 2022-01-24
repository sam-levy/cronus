defmodule SigLive.PayslipTemplates.PayslipTemplateItems.PayslipItemForm do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    Select,
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop payslip_template, :struct, required: true
  prop org, :struct, required: true

  data message, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org} = assigns

    socket =
      socket
      |> assign(assigns)
      |> assign(
        changeset: HR.create_payslip_template_item_change(),
        payslip_categories: HR.list_payslip_categories(org.id)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"payslip_template_item" => params}, socket) do
    %{params: params, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Novo Item do Modelo de Holerite" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:payslip_category_id} class="form-field">
          <Label class="form-label">Categoria do Item de Holerite</Label>
          <Select
            prompt=""
            class="form-input"
            options={payslip_categories_for_select(@payslip_categories)}
          />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:amount} class="form-field">
          <Label class="form-label">Valor</Label>
          <TextInput class="form-input" />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div :if={@message} class="form-error-tag mb-3">{@message}</div>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp validate_params(context) do
    changeset =
      context.params
      |> Map.put("org_id", "id")
      |> Map.put("payslip_template_id", "id")
      |> HR.create_payslip_template_item_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}} = context) do
    %{payslip_template: payslip_template} = context.socket.assigns

    Map.put(
      context,
      :return,
      HR.create_payslip_template_item(payslip_template, changeset.changes)
    )
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, message}} = context) when is_binary(message) do
    {_, changeset} = context.validation

    {:noreply, assign(context.socket, message: message, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) when is_struct(changeset) do
    {:noreply, assign(context.socket, message: nil, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, payslip_template_item}, socket: socket}) do
    %{close_fun: close_fun} = socket.assigns

    HR.broadcast_new_payslip_template_item(payslip_template_item)
    flash_info("Item Criado")
    close_fun.()

    {:noreply, socket}
  end
end
