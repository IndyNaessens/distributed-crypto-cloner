defmodule Assignment.HistoryKeeperManager do
  use GenServer

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def get_pid_for(coin_name) when is_binary(coin_name) do
  end

  def retrieve_history_processes() do
    GenServer.call(__MODULE__, :history)
  end

  # SERVER
  def init(:no_args) do
    {:ok, :no_args, {:continue, :start_history_keeper_workers}}
  end

  def handle_continue(:start_history_keeper_workers, _state) do
    # get supported coin pars
    updated_state =
      Assignment.ProcessManager.retrieve_coin_processes()
      |> Enum.map(fn {coin_name, _pid} ->
        {:ok, pid} = Assignment.HistoryKeeperSupervisor.add_worker(coin_name)
        {coin_name, pid}
      end)

    {:noreply, updated_state}
  end

  # CASTS

  # CALLS
  def handle_call(:history, _from, state) do
    {:reply, state, state}
  end
end
