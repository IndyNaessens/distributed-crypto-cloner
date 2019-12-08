defmodule Assignment.CoindataSupervisor do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children = [
      Assignment.CoindataRetrieverSupervisor,
      Assignment.ProcessManager
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
