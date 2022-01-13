defmodule SigLive.AccountsPayable.List do
  use SigLive, :surface_live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, Field, Label}

  alias Sig.Finance

  alias SigLive.AccountsPayable.PayFooter
  alias SigLive.Components.DropdownOpts

  prop org, :struct, required: true
  prop org_bank_accounts, :list, required: true
  prop payables, :list, required: true
  prop overdue_at, :date, required: true

  data message, :string, default: nil
  data selected_payables, :map, default: %{}
  data selected_method, :atom, default: nil
  data selected_amount_sum, :struct, default: Money.new(0)

  @impl true
  def update(assigns, socket) do
    if socket.assigns.selected_payables == %{} do
      {:ok, assign(socket, assigns)}
    else
      {:ok,
       socket
       |> assign(assigns)
       |> refresh_selected_payables()}
    end
  end

  defp refresh_selected_payables(socket) do
    %{payables: payables, selected_payables: selected_payables} = socket.assigns

    indexed_payables = Map.new(payables, &{&1.id, &1})
    assigns = %{selected_payables: %{}, selected_amount_sum: Money.new(0)}

    selected_payables
    |> Enum.reduce_while(assigns, fn {id, _}, acc ->
      case Map.get(indexed_payables, id) do
        nil -> {:halt, :payable_not_found}
        payable -> {:cont, add_payable(acc, payable)}
      end
    end)
    |> case do
      :payable_not_found -> clear_selected_payables(socket)
      assigns -> assign_selected_payables(socket, assigns)
    end
  end

  @impl true
  def handle_event("clear_selected_payables", _params, socket) do
    {:noreply, clear_selected_payables(socket)}
  end

  @impl true
  def handle_event("select_payable", %{"selected_payable_ids" => payable_ids}, socket) do
    acc = %{selected_payables: %{}, selected_method: nil, selected_amount_sum: Money.new(0)}

    assigns =
      Enum.reduce_while(payable_ids, acc, fn
        {payable_id, "true"}, acc ->
          payable = get_payable(socket, payable_id)

          case Map.get(acc, :selected_method) do
            nil ->
              {:cont,
               acc
               |> Map.put(:selected_method, payable.financial_transaction_type)
               |> add_payable(payable)}

            :check ->
              {:halt, "Não é possivel fazer pagamentos em lote de contas em cheque."}

            method ->
              if method == payable.financial_transaction_type do
                {:cont, add_payable(acc, payable)}
              else
                {:halt, "As contas selecionadas devem possuir a mesma forma de pagamento."}
              end
          end

        {_payable_id, "false"}, acc ->
          {:cont, acc}
      end)

    {:noreply, assign_selected_payables(socket, assigns)}
  end

  @impl true
  def handle_event("select_payable", _params, socket) do
    socket
    |> clear_selected_payables()
    |> assign(:message, nil)
  end

  defp get_payable(socket, payable_id) do
    %{payables: payables, selected_payables: selected_payables} = socket.assigns

    case Map.get(selected_payables, payable_id) do
      nil -> Enum.find(payables, &(&1.id == payable_id))
      payable -> payable
    end
  end

  defp add_payable(acc, %{authorized_by_id: nil}), do: acc

  defp add_payable(acc, payable) do
    sum = acc |> Map.get(:selected_amount_sum) |> Money.add(payable.amount)
    payables = acc |> Map.get(:selected_payables) |> Map.put(payable.id, payable)

    acc
    |> Map.put(:selected_amount_sum, sum)
    |> Map.put(:selected_payables, payables)
  end

  defp assign_selected_payables(socket, %{selected_payables: _} = assigns) do
    socket |> assign(assigns) |> assign(:message, nil)
  end

  defp assign_selected_payables(socket, error) when is_binary(error) do
    assign(socket, :message, error)
  end

  defp clear_selected_payables(socket) do
    assign(socket, cleared_payables())
  end

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <Form for={:selected_payable_ids} change="select_payable">
        <table class="w-full bg-white shadow-lg my-5">
          <thead class="top-0 z-20">
            <tr class="bg-white">
              <th colspan="6">
                <div class="flex justify-between items-center py-3 px-6">
                  <span class="text-gray-500 font-medium tracking-wider">
                    Contas a Pagar
                  </span>
                </div>
              </th>
            </tr>

            <tr
              :if={@payables != []}
              class="bg-gray-100 uppercase text-xs font-medium text-gray-500 tracking-wider"
            >
              <th class="pl-6 pr-3 text-left"></th>
              <th class="py-3 pr-3 text-left">Vencimento</th>
              <th class="px-3 text-left">Empresa</th>
              <th class="px-3 text-left">Descrição</th>
              <th class="px-3 text-left">Destinatário</th>
              <th class="px-3 text-left">Forma</th>
              <th class="px-3 text-right">Valor</th>
              <th class="text-left"></th>
            </tr>
          </thead>

          <tbody class="text-gray-600 text-sm font-light">
            {#for payable <- @payables}
              <tr class={tr_class(@selected_payables, payable)}>
                <td class="py-3 text-left">
                  {#if payable.financial_transaction_id == nil}
                    <Field name={payable.id} class="h-6">
                      <Label class="py-3 pl-6 pr-3">
                        <Checkbox {...checkbox_attrs(@selected_payables, @selected_method, payable)}/>
                      </Label>
                    </Field>
                  {#else}
                    <div class="h-6"></div>
                  {/if}
                </td>

                <td class="pr-3 text-left">
                  {format_date(payable.due_date)}

                  <span :if={Finance.payable_overdue?(payable, @overdue_at)} class="label-red not-italic ml-2">
                    vencido
                  </span>
                </td>

                <td class="px-3 text-left">
                  {#if payable.target == :payslip}
                    {payable.employee_registration_company.trade_name}
                  {/if}
                </td>

                <td class="px-3 text-left">
                  {payable.description}
                </td>

                <td class="px-3 text-left">
                  {#if payable.target == :payslip}
                    {payable.employee.name}
                  {/if}
                </td>

                <td class="px-3 text-left">
                  {capitalize_type(payable.financial_transaction_type)}
                </td>

                <td class="px-3 text-right">
                  {#case payable}
                    {#match %{authorized_by_id: nil}}
                      <span class="label-gray not-italic mr-1">
                        bloqueado
                      </span>
                    {#match %{financial_transaction: %{clearing_date: nil}}}
                      <span class="label-yellow not-italic mr-1">
                        liq pendente
                      </span>
                    {#match %{financial_transaction: %{clearing_date: clearing_date}}}
                      <span class="label-blue not-italic mr-1">
                        pago {format_date(clearing_date)}
                      </span>
                    {#match _}
                  {/case}

                  {payable.amount}
                </td>

                <td class="pr-5 text-right">
                  <DropdownOpts>
                    <a
                      :if={payable.target == :payslip}
                      href={Routes.sig_employee_registrations_show_path(@socket, :payslip, @org, payable.payslip.registration_id, payable.payslip)}
                      target="_blank"
                      class="dropdown-item not-italic"
                    >
                      Visualizar holerite
                    </a>
                  </DropdownOpts>
                </td>
              </tr>
            {/for}
          </tbody>
        </table>
      </Form>

      <PayFooter
        :if={@selected_payables != %{}}
        id="pay_footer"
        close_event="clear_selected_payables"
        close_fun={fn -> close_form(@id) end}
        {=@org_bank_accounts}
        {=@org}
        {=@message}
        {=@selected_method}
        {=@selected_payables}
        {=@selected_amount_sum}
      />
    </div>
    """
  end

  def close_form(id), do: send_update(__MODULE__, cleared_payables(id))

  defp cleared_payables do
    [
      selected_payables: %{},
      selected_method: nil,
      selected_amount_sum: Money.new(0)
    ]
  end

  defp cleared_payables(id), do: cleared_payables() ++ [id: id]

  defp tr_class(_selected_payables, %{authorized_by_id: nil}) do
    "border-b border-gray-200 hover:bg-gray-50 text-gray-400 italic"
  end

  defp tr_class(selected_payables, payable) do
    if Map.get(selected_payables, payable.id, false) do
      "outline-blue-300 outline-1 outline-offset-2 bg-blue-100"
    else
      "border-b border-gray-200 hover:bg-gray-50"
    end
  end

  @checkbox_enabled_class ~w(h-5 w-5 form-checkbox focus:ring-0 focus:ring-offset-0 active:ring-offset-0")
  @checkbox_disabled_class ~w(h-5 w-5 form-checkbox-disabled)

  defp checkbox_attrs(selected_payables, selected_method, payable) do
    []
    |> disable(selected_method, selected_payables, payable)
    |> check(selected_payables, payable.id)
  end

  defp disable(attrs, _selected_method, _selected_payables, %{authorized_by_id: nil}) do
    do_disable(attrs)
  end

  defp disable(attrs, nil, _selected_payables, _payable) do
    Keyword.put(attrs, :class, @checkbox_enabled_class)
  end

  defp disable(attrs, :check, selected_payables, %{financial_transaction_type: :check} = payable) do
    case Map.get(selected_payables, payable.id) do
      %{} -> Keyword.put(attrs, :class, @checkbox_enabled_class)
      nil -> do_disable(attrs)
    end
  end

  defp disable(attrs, method, _selected_payables, %{financial_transaction_type: method}) do
    Keyword.put(attrs, :class, @checkbox_enabled_class)
  end

  defp disable(attrs, _selected_method, _selected_payables, _payable) do
    do_disable(attrs)
  end

  defp do_disable(attrs) do
    opts =
      attrs
      |> Keyword.get(:opts, [])
      |> Keyword.put(:disabled, true)

    attrs
    |> Keyword.put(:class, @checkbox_disabled_class)
    |> Keyword.put(:opts, opts)
  end

  defp check(attrs, selected_payables, payable_id) do
    if Map.get(selected_payables, payable_id, false) do
      opts =
        attrs
        |> Keyword.get(:opts, [])
        |> Keyword.put(:checked, true)

      Keyword.put(attrs, :opts, opts)
    else
      attrs
    end
  end
end
