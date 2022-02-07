defmodule SigLive.Users.NewUserForm do
  use SigLive, :surface_live_component

  alias Sig.Accounts
  alias Sig.Accounts.User
  alias Sig.Entities

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    Select,
    TextInput,
    PasswordInput,
    ErrorTag,
    Field,
    Label,
    Submit
  }

  alias SigLive.Components.Modal

  prop close_event, :event, required: true
  prop close_fun, :fun, required: true
  prop form_open, :boolean, required: true
  prop broadcast_opts, :keyword, required: true
  prop org, :struct, required: true

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(
        individuals: Entities.list_individuals(assigns.org),
        changeset: Accounts.change_user_registration(%User{})
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"user" => params}, socket) do
    %{org: org, broadcast_opts: broadcast_opts} = socket.assigns

    params = Map.put(params, "org_id", org.id)

    case Accounts.register_user(params) do
      {:ok, _user} ->
        flash_info("Usuário criado")
        Accounts.broadcast_users(org, broadcast_opts)
        socket.assigns.close_fun.()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Modal title="Criar Usuário" close={@close_event}>
      <Form for={@changeset} submit="save" opts={autocomplete: "off"}>
        <Field name={:individual_id}>
          <Label class="form-label">Pessoa</Label>
          <Select options={Map.new(@individuals, &{&1.name, &1.entity_id})} prompt="" class="form-input" />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:email} class="form-field">
          <Label class="form-label">Email</Label>
          <TextInput class="form-input" />
          <ErrorTag class="form-error-tag" />
        </Field>

        <Field name={:password} class="form-field">
          <Label class="form-label">Senha</Label>
          <PasswordInput class="form-input" />
          <ErrorTag class="form-error-tag" />
        </Field>

        <div class="flex justify-end">
          <Submit class="btn-blue" label="Salvar" opts={phx_disable_with: "Salvando..."} />
        </div>
      </Form>
    </Modal>
    """
  end
end
