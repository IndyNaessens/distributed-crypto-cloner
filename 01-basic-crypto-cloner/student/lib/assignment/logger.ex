defmodule Assignment.Logger do
  @moduledoc """
  Simple logger that can log messages to the terminal.

  We don't keep any state.
  """
  use GenServer

  ### API ###
  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def log(level, message) do
    GenServer.cast(__MODULE__, {level, message})
  end

  def log_and_pass(value, level, message) do
    Assignment.Logger.log(level, message)
    value
  end

  ### SERVER ###
  def init(:no_args) do
    {:ok, nil}
  end

  ### CALLS ###

  ### CASTS ###
  def handle_cast({:debug, message}, state) do
    write_to_terminal("[debug] #{message}")
    {:noreply, state}
  end

  def handle_cast({:info, message}, state) do
    write_to_terminal("[info] #{message}")
    {:noreply, state}
  end

  def handle_cast({:warn, message}, state) do
    write_to_terminal("[warning] #{message}")
    {:noreply, state}
  end

  def handle_cast({:error, message}, state) do
    write_to_terminal("[error] #{message}")
    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  ### INFO ###

  ### HELPERS ###
  defp write_to_terminal(message) when is_binary(message) do
    IO.puts(message)
  end
end
