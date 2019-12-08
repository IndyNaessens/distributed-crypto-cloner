defmodule Assignment.HistoryKeeperSupervisor do
    @moduledoc """
  This is the HistoryKeeperSupervisor module.

  It supervises the following modules with a rest_for_one strategy
   - HistoryKeeperWorkerSupervisor
   - HistoryKeeperManager
  """
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      Assignment.HistoryKeeperWorkerSupervisor,
      Assignment.HistoryKeeperManager
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
