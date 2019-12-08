defmodule Assignment.HistoryKeeperWorkerSupervisor do
  use DynamicSupervisor

  # API
  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_worker(coin_name) do
    spec = {Assignment.HistoryKeeperWorker, coin_name}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  # SERVER
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
