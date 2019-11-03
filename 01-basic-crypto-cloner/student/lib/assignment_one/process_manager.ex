defmodule AssignmentOne.ProcessManager do
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

    {:noreply, state ++ [{coin_name, pid}]}
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
    # state
    # |> Enum.find( fn {_, pid} -> pid_gone == pid end )
    # |> elem(0)
    # |> start_worker()
    IO.puts("DOWN: #{inspect(pid_gone)}")

    {:noreply, state}
  end
end
