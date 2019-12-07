defmodule Assignment.ProcessManager do
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
  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def retrieve_coin_processes() do
    GenServer.call(__MODULE__, :retrieve_coin_processes)
  end

  def send_request_to_all(request) do
    GenServer.cast(__MODULE__, {:send_request_to_all, request})
  end

  ### SERVER ###
  def init(:no_args) do
    {:ok, :no_args, {:continue, :start_processes}}
  end

  def handle_continue(:start_processes, _state) do
    updated_state =
      Assignment.PoloniexAPiCaller.return_ticker()
      |> Map.keys()
      |> Enum.map(fn coin_name ->
        {:ok, pid} = Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)
        {coin_name, pid}
      end)

    # send_request_to_all(:request_work_permission)
    {:noreply, updated_state}
  end

  ### CALLS ###
  def handle_call(:retrieve_coin_processes, _from, state) do
    {:reply, state, state}
  end

  ### CASTS ###
  def handle_cast({:send_request_to_all, request}, state) do
    state
    |> Enum.each(fn {_, pid} ->
      GenServer.cast(pid, request)
    end)

    {:noreply, state}
  end

  ### INFO ###
end
