defmodule Assignment.CoindataCoordinator do
  use GenServer

  # API
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_coin(coin_name) when is_binary(coin_name) do
    GenServer.cast(__MODULE__, {:add_coin, coin_name})
  end

  def add_coin(coin_name, history_keeper_worker_state)
      when is_map(history_keeper_worker_state) and is_binary(coin_name) do
    GenServer.cast(__MODULE__, {:add_coin, coin_name, history_keeper_worker_state})
  end

  def get_history_keeper_worker_statistics() do
    GenServer.call(__MODULE__, :get_history_keeper_worker_statistics)
  end

  @doc """
  Transfers a HistoryKeeperWorker and CoindataRetriever responsible for the given coin_name
  from the current node to the node_to
  """
  def transfer_coin(coin_name, node_to) do
    GenServer.cast(__MODULE__, {:transfer_coin, coin_name, node_to})
  end

  def balance() do

  end

  # SERVER
  def init([]) do
    {:ok, [], {:continue, :continue}}
  end

  def handle_continue(:continue, state) do
    # check how many cloner nodes are in the cluster
    # expects the short name of the reporter node to contain "reporter"
    amount_of_cloner_nodes =
      Node.list()
      |> Enum.map(&(Atom.to_string(&1) |> String.split("@") |> List.first() |> String.downcase()))
      |> Enum.filter(&(!String.contains?(&1, "reporter")))
      |> length

    # when we have zero cloner nodes, start cloning as first node
    if amount_of_cloner_nodes == 0 do
      Assignment.PoloniexAPiCaller.return_ticker()
      |> Map.keys()
      |> Enum.take(25)
      |> Enum.each(&add_coin(&1))
    end

    {:noreply, state}
  end

  def handle_cast({:add_coin, coin_name}, state) do
    # start the workers
    Assignment.HistoryKeeperWorkerSupervisor.add_worker(coin_name)
    Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)

    {:noreply, state}
  end

  def handle_cast({:add_coin, coin_name, history_keeper_worker_state}, state) do
    # start the workers
    Assignment.HistoryKeeperWorkerSupervisor.add_worker(history_keeper_worker_state)
    Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)

    {:noreply, state}
  end

  def handle_cast({:transfer_coin, coin_name, node_to}, state) do
    # get retriever and keeper pid
    {retriever_pid, keeper_pid} =
      {Assignment.ProcessManager.get_pid_for(coin_name),
       Assignment.HistoryKeeperManager.get_pid_for(coin_name)}

    # get state frrom historykeeper
    state_from_keeper = Assignment.HistoryKeeperWorker.get_state(keeper_pid)

    # stop retriever and keeper
    GenServer.stop(retriever_pid)
    GenServer.stop(keeper_pid)

    # start keeper with state and start retriever on new node
    GenServer.cast(
      {Assignment.CoindataCoordinator, node_to},
      {:add_coin, coin_name, state_from_keeper}
    )

    {:noreply, state}
  end

  def handle_call(:get_history_keeper_worker_statistics, _from, state) do
    pairs =
      Assignment.HistoryKeeperManager.retrieve_history_processes()
      |> Enum.map(fn {_coin, pid} -> Assignment.HistoryKeeperWorker.get_statistics(pid) end)

    {:reply, pairs, state}
  end
end
