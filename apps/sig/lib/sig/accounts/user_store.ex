defmodule Sig.Accounts.UserStore do
  use GenServer

  alias Sig.Accounts.User

  @name __MODULE__

  # One day
  @clear_interval 86_400_000

  def start_link([]) do
    GenServer.start_link(@name, @name, name: @name)
  end

  @doc """
  Used for tests.
  """
  def start_link([{:name, test_table_name}]) do
    GenServer.start_link(@name, test_table_name, name: test_table_name)
  end

  def insert({token, %User{} = user}, table \\ @name) when is_binary(token) do
    GenServer.call(table, {:insert, token, user})
  end

  def delete(token, table \\ @name)

  def delete(token, table) when is_binary(token) do
    GenServer.call(table, {:delete, token})
  end

  def delete(tokens, table) when is_list(tokens) do
    Enum.each(tokens, &delete(&1, table))
  end

  def fetch(token, table \\ @name) when is_binary(token) do
    case :ets.lookup(table, token) do
      [{_token, user}] -> {:ok, user}
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def init(table) do
    :ets.new(table, [:named_table, :set, :protected, read_concurrency: true])

    Process.send_after(self(), :clear_table, @clear_interval)

    {:ok, table}
  end

  @impl true
  def handle_call({:insert, token, user}, _from, table) do
    :ets.insert(table, {token, user})

    {:reply, :ok, table}
  end

  @impl true
  def handle_call({:delete, token}, _from, table) do
    :ets.delete(table, token)

    {:reply, :ok, table}
  end

  @impl true
  def handle_info(:clear_table, table) do
    :ets.delete_all_objects(table)

    {:noreply, table}
  end
end
