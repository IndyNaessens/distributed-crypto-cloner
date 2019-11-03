defmodule AssignmentOne.Logger do
  use GenServer

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def log(message) do
    GenServer.cast(__MODULE__, {:simple_log, message})
  end

  ### SERVER ###
  def init(state) do
    {:ok, state}
  end

  ### CALLS ###

  ### CASTS ###
  def handle_cast({:simple_log, message}, current_state) do
    write_to_terminal(message)
    {:noreply, current_state}
  end

  ### INFO ###

  ### HELPERS ###
  defp write_to_terminal(message) when is_binary(message) do
    IO.puts(message)
  end
end
