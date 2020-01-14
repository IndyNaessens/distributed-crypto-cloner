defmodule Assignment.HistoryKeeperSupervisor do
    @moduledoc """
  This is the HistoryKeeperSupervisor module.

  It supervises the following modules with a one_for_one strategy
   - HistoryKeeperWorkerSupervisor
   - HistoryKeeper.Registry
  """
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      { Registry, keys: :unique, name: Assignment.HistoryKeeper.Registry },
      Assignment.HistoryKeeperWorkerSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
