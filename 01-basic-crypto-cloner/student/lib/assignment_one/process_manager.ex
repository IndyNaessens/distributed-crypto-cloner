defmodule AssignmentOne.ProcessManager do
  @moduledoc """
  A process manager that manages CoindataRetriever processes.

  State:
  We keep a list of all started CoindataRetriever processes.
  Each entry in the list is a tuple containg 2 elements

  First element => the name of the coin
  Second element => the pid of the started CoindataRetriever

  When processes exit for any reason we will simply start
  a new CoindataRetriever process that wil handle the same coin.
  """
  use GenServer

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
    {:reply, state, state}
  end

  ### CASTS ###
  def handle_cast({:start_coin_process, coin_name}, state) do
    {:ok, pid} = AssignmentOne.CoindataRetriever.start(coin_name)
    Process.monitor(pid)

    {:noreply, Enum.concat(state, [{coin_name, pid}])}
  end

  def handle_cast({:send_request_to_all, request}, state) do
    state
    |> Enum.each(fn {_, pid} ->
      GenServer.cast(pid, request)
    end)

    {:noreply, state}
  end

  ### INFO ###
  def handle_info({:DOWN, _ref, :process, pid_gone, _reason}, state) do
    # get pair that is down
    {coin_name, pid} = Enum.find(state, fn {_, pid} -> pid_gone == pid end)

    # start a new process and monitor it
    {:ok, new_pid} = AssignmentOne.CoindataRetriever.start(coin_name)
    Process.monitor(new_pid)

    # remove it from the list and add the started process
    new_state =
      state
      |> List.delete({coin_name, pid})
      |> Enum.concat([{coin_name, new_pid}])

    {:noreply, new_state}
  end
end
