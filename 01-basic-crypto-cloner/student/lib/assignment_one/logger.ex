defmodule AssignmentOne.Logger do
  @moduledoc """
  Simple logger that can log messages to the terminal.

  We don't keep any state.
  """
  use GenServer

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def log(message) do
    GenServer.cast(__MODULE__, {:simple_log, message})
  end

  def log_and_pass(value, message) do
    AssignmentOne.Logger.log(message)
    value
  end

  ### SERVER ###
  def init(state) do
    {:ok, state}
  end

  ### CALLS ###

  ### CASTS ###
  def handle_cast({:simple_log, message}, state) do
    write_to_terminal(message)
    {:noreply, state}
  end

  ### INFO ###

  ### HELPERS ###
  defp write_to_terminal(message) when is_binary(message) do
    IO.puts(message)
  end
end
