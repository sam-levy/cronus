defmodule SigLive.PayslipTemplates.Form do
  use SigLive, :surface_live_component

  alias Sig.HR

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :show_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop payslip_template_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, payslip_template_id: payslip_template_id} = assigns
    payslip_template = get_payslip_template(org, payslip_template_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        payslip_template: payslip_template,
        changeset: set_changeset(payslip_template)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"payslip_template" => params}, socket) do
    %{params: params, form_state: socket.assigns.form_state, socket: socket}
    |> validate_params()
    |> persist()
    |> handle_return()
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title={handle_title(@form_state)} close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:name} class="form-field">
          <Label class="form-label">Nome</Label>
          <TextInput class="form-input" />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>
    </Modal>
    """
  end

  def states, do: @form_states

  defp get_payslip_template(_org, nil), do: nil

  defp get_payslip_template(org, payslip_template_id) do
    HR.get_payslip_template(org, payslip_template_id)
  end

  defp set_changeset(nil), do: HR.create_payslip_template_change()
  defp set_changeset(payslip_template), do: HR.update_payslip_template_change(payslip_template)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> HR.create_payslip_template_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{payslip_template: payslip_template} = context.socket.assigns

    changeset = HR.update_payslip_template_change(payslip_template, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{org: org} = context.socket.assigns

    Map.put(context, :return, HR.create_payslip_template(org, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{payslip_template: payslip_template} = context.socket.assigns

    Map.put(context, :return, HR.update_payslip_template(payslip_template, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, payslip_template}, socket: socket}) do
    %{form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, payslip_template)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, payslip_template) do
    HR.broadcast_new_payslip_template(payslip_template)
  end

  defp handle_broadcast(:edit_mode, payslip_template) do
    HR.broadcast_updated_payslip_template(payslip_template)
  end

  defp handle_flash(:new_mode), do: flash_info("Modelo de Holerite criado")
  defp handle_flash(:edit_mode), do: flash_info("Modelo de Holerite alterado")

  defp handle_title(:new_mode), do: "Novo Modelo de Holerite"
  defp handle_title(:edit_mode), do: "Renomear Modelo de Holerite"
end
