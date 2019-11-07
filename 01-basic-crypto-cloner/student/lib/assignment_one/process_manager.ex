defmodule AssignmentOne.ProcessManager do
  @moduledoc """
  A process manager that manages CoindataRetriever processes.

  State:
  We keep a Map of all started CoindataRetriever processes.

  The key represents the pid
  And the value consist of the coin_name and the pid as a tuple

  When processes exit for any reason we will simply start
  a new CoindataRetriever process that wil handle the same coin.
  """
  use GenServer

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def retrieve_coin_processes() do
    GenServer.call(__MODULE__, :retrieve_coin_processes)
  end

  def start_coin_process(coin_name) when is_binary(coin_name) do
    GenServer.cast(__MODULE__, {:start_coin_process, coin_name})
  end

  def send_request_to_all(request) do
    GenServer.cast(__MODULE__, {:send_request_to_all, request})
  end

  ### SERVER ###
  def init(state) do
    {:ok, state}
  end

  ### CALLS ###
  def handle_call(:retrieve_coin_processes, _from, state) do
    {:reply, Map.values(state), state}
  end

  ### CASTS ###
  def handle_cast({:start_coin_process, coin_name}, state) do
    {:ok, pid} = AssignmentOne.CoindataRetriever.start(coin_name)
    Process.monitor(pid)

    {:noreply, Map.put(state, pid, {coin_name, pid})}
  end

  def handle_cast({:send_request_to_all, request}, state) do
    state
    |> Map.values()
    |> Enum.each(fn {_, pid} ->
      GenServer.cast(pid, request)
    end)

    {:noreply, state}
  end

  ### INFO ###
  def handle_info({:DOWN, _ref, :process, pid_gone, _reason}, state) do
    # get pair for pid_gone
    {coin_name, pid_gone} = Map.get(state, pid_gone)

    # start a new process and monitor it
    {:ok, pid} = AssignmentOne.CoindataRetriever.start(coin_name)
    Process.monitor(pid)

    # new state
    new_state =
      state
      |> Map.delete(pid_gone)
      |> Map.put(pid, {coin_name, pid})

    # new state needs the new pair
    {:noreply, new_state}
  end
end
