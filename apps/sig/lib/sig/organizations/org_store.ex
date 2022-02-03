defmodule Sig.Organizations.OrgStore do
  use GenServer

  alias Sig.Organizations.Org
  alias Sig.Repo

  @name __MODULE__

  def start_link([]) do
    GenServer.start_link(@name, nil, name: @name)
  end

  @doc """
    Used only for tests.
  """
  def start_link([{:name, test_table_name}]) do
    GenServer.start_link(@name, test_table_name, name: test_table_name)
  end

  def refresh_store(table \\ @name) do
    GenServer.call(table, :refresh_store)
  end

  def fetch_org(id, table \\ @name) when is_binary(id) do
    case :ets.lookup(table, id) do
      [{_id, org}] -> {:ok, org}
      _ -> {:error, :not_found}
    end
  end

  def get_org(id, table \\ @name) when is_binary(id) do
    case fetch_org(id, table) do
      {:ok, org} -> org
      {:error, :not_found} -> nil
    end
  end

  @impl true
  def init(nil) do
    :ets.new(@name, [:named_table, :set, :protected, read_concurrency: true])

    do_refresh_store(@name)

    {:ok, @name}
  end

  @doc """
    Used only for tests. It doesn't initialize the state in order to
    allow the process to have the DB access granted before inserting data.
  """
  @impl true
  def init(test_table_name) do
    :ets.new(test_table_name, [:named_table, :set, :protected, read_concurrency: true])

    {:ok, test_table_name}
  end

  @impl true
  def handle_call(:refresh_store, _from, table) do
    do_refresh_store(table)

    {:reply, table, table}
  end

  defp do_refresh_store(table) do
    case Repo.all(Org) do
      [] ->
        :ok

      orgs when is_list(orgs) ->
        :ets.insert(table, Enum.map(orgs, &{&1.id, &1}))
    end
  end
end
