defmodule Assignment.HistoryKeeperSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__,:no_args, name: __MODULE__)
  end

  def init(:no_args) do
   children = [
    Assignment.HistoryKeeperWorkerSupervisor,
    Assignment.HistoryKeeperManager
   ]

   Supervisor.init(children, strategy: :rest_for_one)
  end
end
