defmodule SigLive.Organizations.Sectors.Form do
  use SigLive, :surface_live_component

  alias Sig.Organizations

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    TextInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  @form_states [:new_mode, :edit_mode, :closed]

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_state, :atom, required: true, values!: @form_states
  prop org, :struct, required: true
  prop org_sector_id, :string, default: nil

  @impl true
  def update(assigns, socket) do
    %{org: org, org_sector_id: org_sector_id} = assigns

    org_sector = get_org_sector(org, org_sector_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        org_sector: org_sector,
        changeset: set_changeset(org_sector)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"sector" => params}, socket) do
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
          <TextInput class="form-input" opts={phx_hook: "SelectInputContent"} />
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

  defp get_org_sector(_org, nil), do: nil
  defp get_org_sector(org, org_sector_id), do: Organizations.get_org_sector(org, org_sector_id)

  defp set_changeset(nil), do: Organizations.org_sector_change()
  defp set_changeset(org_sector), do: Organizations.org_sector_change(org_sector)

  defp validate_params(%{form_state: :new_mode} = context) do
    changeset =
      context.params
      |> Map.put("org_id", "org_id")
      |> Organizations.org_sector_change()

    case apply_action(changeset, :insert) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp validate_params(%{form_state: :edit_mode} = context) do
    %{org_sector: org_sector} = context.socket.assigns

    changeset = Organizations.org_sector_change(org_sector, context.params)

    case apply_action(changeset, :update) do
      {:error, changeset} -> Map.put(context, :validation, {:error, changeset})
      {:ok, _schema} -> Map.put(context, :validation, {:ok, changeset})
    end
  end

  defp persist(%{validation: {:error, _}} = context), do: context

  defp persist(%{validation: {:ok, changeset}, form_state: :new_mode} = context) do
    %{org: org} = context.socket.assigns

    Map.put(context, :return, Organizations.create_org_sector(org, changeset.changes))
  end

  defp persist(%{validation: {:ok, changeset}, form_state: :edit_mode} = context) do
    %{org_sector: org_sector} = context.socket.assigns

    Map.put(context, :return, Organizations.update_org_sector(org_sector, changeset.changes))
  end

  defp handle_return(%{validation: {:error, changeset}, socket: socket}) do
    {:noreply, assign(socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:error, changeset}} = context) do
    {:noreply, assign(context.socket, changeset: changeset)}
  end

  defp handle_return(%{return: {:ok, org_sector}, socket: socket}) do
    %{form_state: form_state, close_fun: close_fun} = socket.assigns

    handle_broadcast(form_state, org_sector)
    handle_flash(form_state)
    close_fun.()

    {:noreply, socket}
  end

  defp handle_broadcast(:new_mode, org_sector) do
    Organizations.broadcast_new_org_sector(org_sector)
  end

  defp handle_broadcast(:edit_mode, org_sector) do
    Organizations.broadcast_updated_org_sector(org_sector)
  end

  defp handle_flash(:new_mode), do: flash_info("Setor criado")
  defp handle_flash(:edit_mode), do: flash_info("Setor alterado")

  defp handle_title(:new_mode), do: "Novo Setor"
  defp handle_title(:edit_mode), do: "Renomear Setor"
end
