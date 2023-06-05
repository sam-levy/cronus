defmodule Sig.Organizations.OrgStore do
  use GenServer

  alias Sig.Organizations.Org

  @name __MODULE__

  # One day
  @clear_interval 86_400_000

  def start_link([]) do
    GenServer.start_link(@name, @name, name: @name)
  end

  @doc """
  Used only for tests.
  """
  def start_link([{:name, test_table_name}]) do
    GenServer.start_link(@name, test_table_name, name: test_table_name)
  end

  def insert({id, %Org{} = org}, table \\ @name) when is_binary(id) do
    GenServer.call(table, {:insert, id, org})
  end

  def fetch(id, table \\ @name) when is_binary(id) do
    case :ets.lookup(table, id) do
      [{_id, org}] -> {:ok, org}
      _ -> {:error, :not_found}
    end
  end

  def get(id, table \\ @name) when is_binary(id) do
    case fetch(id, table) do
      {:ok, org} -> org
      {:error, :not_found} -> nil
    end
  end

  @impl true
  def init(test_table_name) do
    :ets.new(test_table_name, [:named_table, :set, :protected, read_concurrency: true])

    Process.send_after(self(), :clear_table, @clear_interval)

    {:ok, test_table_name}
  end

  @impl true
  def handle_call({:insert, id, org}, _from, table) do
    :ets.insert(table, {id, org})

    {:reply, :ok, table}
  end

  @impl true
  def handle_info(:clear_table, table) do
    :ets.delete_all_objects(table)

    Process.send_after(self(), :clear_table, @clear_interval)

    {:noreply, table}
  end
end
