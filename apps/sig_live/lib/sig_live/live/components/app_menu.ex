defmodule SigLive.Components.AppMenu do
  use SigLive, :surface_live_component

  alias Surface.Components.LivePatch

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
    <div class="group relative z-20" x-data="{ isOpen: false }" @click.away="isOpen = false">
      <div class="p-1 mr-3 group-hover:bg-gray-300 rounded cursor-pointer" @mouseover="isOpen = true">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-6 w-6 text-gray-600 transition-transform duration-300 transform"
          fill="none"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M4 6h16M4 12h16M4 18h16"
          />
        </svg>
      </div>

      <div
        class="absolute origin-top-left -left-2 z-10 p-1.5 mt-2 min-w-max w-40 rounded-md shadow-3xl bg-white ring-1 ring-black ring-opacity-5 focus:outline-none"
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
            <div class="dropdown-title mb-1">RH</div>
            <LivePatch class="dropdown-item" to={Routes.sig_individuals_index_path(@socket, :index, @org)}>
              Pessoas
            </LivePatch>

            <LivePatch
              class="dropdown-item"
              to={Routes.sig_payslip_groups_index_path(@socket, :payslip_groups, @org)}
            >
              Holerites
            </LivePatch>
          </div>

          <div>
            <div class="dropdown-title mb-1">Financeiro</div>

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
            <div class="dropdown-title mb-1">Relatórios</div>
            <LivePatch class="dropdown-item" to={Routes.sig_reports_hr_path(@socket, :hr_reports, @org)}>
              RH
            </LivePatch>
          </div>

          <div>
            <div class="dropdown-title mb-1">Configurações</div>

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

          <div>
            <div class="dropdown-title mb-1">Sessão</div>

            {link("Sair",
              to: Routes.user_session_path(@socket, :delete),
              method: :delete,
              class: "dropdown-item"
            )}

            {link("Alterar Senha",
              to: Routes.user_settings_path(@socket, :edit),
              class: "dropdown-item"
            )}
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
