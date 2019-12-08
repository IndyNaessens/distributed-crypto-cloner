defmodule Assignment.CoindataSupervisor do
  @moduledoc """
  This is the CoindataSupervisor module.

  It supervises the following modules with a rest_for_one strategy
   - CoindataRetrieverSupervisor
   - ProcessManager
  """
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      Assignment.CoindataRetrieverSupervisor,
      Assignment.ProcessManager
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
