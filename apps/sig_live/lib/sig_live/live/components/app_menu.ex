defmodule SigLive.Components.AppMenu do
  use SigLive, :surface_live_component

  alias Surface.Components.LivePatch

  alias SigLive.Components.Icon

  slot default
  prop org, :struct, required: true

  @impl true
  def render(assigns) do
    ~F"""
    <div class="flex items-center my-4 font-light">
      <.menu org={@org} socket={@socket} />

      <#slot />
    </div>
    """
  end

  def menu(assigns) do
    ~F"""
    <div class="relative z-20" x-data="{ isOpen: false }" @click.away="isOpen = false">
      <div class="p-1 mr-3 hover:bg-gray-300 rounded" @mouseover="isOpen = true">
        <Icon name="menu" class="text-gray-600" />
      </div>

      <div
        class="dropdown-list origin-top-left left-0"
        @mouseleave="isOpen = false"
        @click="isOpen = false"
        x-cloak
        x-show="isOpen"
        x-transition:enter="transition ease-out duration-75"
        x-transition:enter-start="transform opacity-0 scale-95"
        x-transition:enter-end="transform opacity-100 scale-100"
        x-transition:leave="transition ease-in duration-75"
        x-transition:leave-start="transform opacity-100 scale-100"
        x-transition:leave-end="transform opacity-0 scale-95"
      >
        <div class="space-y-5 my-2">
          <div>
            <div class="dropdown-title">RH</div>
            <LivePatch
              class="dropdown-item"
              to={Routes.sig_individuals_index_path(@socket, :index, @org)}
            >
              Pessoas
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_payslip_groups_list_path(@socket, :payslip_groups, @org)}
            >
              Holerites
            </LivePatch>
          </div>

          <div>
            <div class="dropdown-title">Financeiro</div>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_accounts_payable_index_path(@socket, :accounts_payable, @org)}
            >
              Contas a Pagar
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_accounts_payable_index_path(@socket, :financial_transactions, @org)}
            >
              Transações Financeiras
            </LivePatch>
          </div>

          <div>
            <div class="dropdown-title">Configurações</div>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_organizations_show_path(@socket, :organizations, @org)}
            >
              Setores e Cargos
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_payslip_categories_index_path(@socket, :payslip_categories, @org)}
            >
              Categorias de Itens de Holerite
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_payslip_templates_index_path(@socket, :payslip_templates, @org)}
            >
              Modelos de Holerites
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_payslip_recurring_item_models_index_path(@socket, :payslip_recurring_item_models, @org)}
            >
              Modelos de Itens de Holerite
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_benefit_models_index_path(@socket, :benefit_models, @org)}
            >
              Modelos de Benefícios de Funcionários
            </LivePatch>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule SigLive.Components.AppMenu.Breadcrumb do
  use SigLive, :surface_component

  alias Surface.Components.LivePatch

  prop name, :string, required: true
  prop path, :string
  prop noslash, :boolean, default: false

  @impl true
  def render(assigns) do
    ~F"""
    <div class="" style="font-size: 15px;">
      <span :if={!@noslash} class="text-gray-400 font-thin">/</span>

      {#if @path}
        <LivePatch to={@path} class={item_class()}>
          {@name}
        </LivePatch>
      {#else}
        <span class={~w(cursor-default) ++ item_class()}>
          {@name}
        </span>
      {/if}
    </div>
    """
  end

  defp item_class do
    ~w(p-1 mr-1 text-gray-500 hover:bg-gray-300 rounded)
  end
end
