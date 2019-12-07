defmodule Assignment.CoindataSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def init(:no_args) do
    children = [
      Assignment.CoindataRetrieverSupervisor,
      Assignment.ProcessManager
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
