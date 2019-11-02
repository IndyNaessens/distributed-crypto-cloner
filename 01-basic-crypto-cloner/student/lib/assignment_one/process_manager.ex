defmodule AssignmentOne.ProcessManager do
  use GenServer

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ### SERVER ###
  def init(state) do
    {:ok, state}
  end
end
