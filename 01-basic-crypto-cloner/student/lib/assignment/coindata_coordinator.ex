defmodule Assignment.CoindataCoordinator do
  use GenServer

  # API
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_coin(coin_name) when is_binary(coin_name) do
    GenServer.cast(__MODULE__, {:add_coin, coin_name})
  end

  def get_history_keeper_worker_statistics() do
    GenServer.call(__MODULE__, :get_history_keeper_worker_statistics)
  end

  def balance() do
  end

  # SERVER
  def init([]) do
    {:ok, [], {:continue, :continue}}
  end

  def handle_continue(:continue, state) do
    # TODO check if only node in cluster

    # only node in cluster so add coins
    Assignment.PoloniexAPiCaller.return_ticker()
    |> Map.keys()
    |> Enum.take(20)
    |> Enum.each(&add_coin(&1))

    {:noreply, state}
  end

  def handle_cast({:add_coin, coin_name}, state) do
    # prepare the workers
    Assignment.HistoryKeeperWorkerSupervisor.add_worker(coin_name)
    {:ok, pid} = Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)

    # start work for coin
    GenServer.cast(pid, :request_work_permission)

    {:noreply, state}
  end

  def handle_call(:get_history_keeper_worker_statistics, _from, state) do
    pairs =
      Assignment.HistoryKeeperManager.retrieve_history_processes()
      |> Enum.map(fn {_coin, pid} -> Assignment.HistoryKeeperWorker.get_statistics(pid) end)

    {:reply, pairs, state}
  end
end
