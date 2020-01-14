defmodule Assignment.CoindataSupervisor do
  @moduledoc """
  This is the CoindataSupervisor module.

  It supervises the following modules with a one_for_one strategy
   - CoindataRetrieverSupervisor
   - Coindata.Registry
  """
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      { Registry, keys: :unique, name: Assignment.Coindata.Registry },
      Assignment.CoindataRetrieverSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
