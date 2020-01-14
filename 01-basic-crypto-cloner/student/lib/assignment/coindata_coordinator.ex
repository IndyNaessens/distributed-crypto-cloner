defmodule Assignment.CoindataCoordinator do
  def start() do
    # TODO check if only node in cluster

    # only node in cluster so add coins
    Assignment.PoloniexAPiCaller.return_ticker()
    |> Map.keys()
    |> Enum.take(5)
    |> Enum.each(&add_coin(&1))

    # start the work
    Assignment.ProcessManager.retrieve_coin_processes()
    |> Enum.each(fn {_coin, pid} -> GenServer.cast(pid, :request_work_permission) end)
  end

  def add_coin(coin_name) when is_binary(coin_name) do
    Assignment.HistoryKeeperWorkerSupervisor.add_worker(coin_name)
    Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)
  end

  def balance() do

  end
end
