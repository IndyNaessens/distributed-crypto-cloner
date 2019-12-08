defmodule Assignment.HistoryKeeperManager do
  @moduledoc """
  This is the HistoryKeeperManager module

  It starts HistoryKeeperWorkers using a DynamicSupervisor
  After they are started we can call this module instead of the DynamicSupervisor
  for data
  """
  use GenServer

  # API
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_pid_for(coin_name) when is_binary(coin_name) do
    pid = GenServer.call(__MODULE__, {:get_pid_for_coin, coin_name})

    case pid do
      # it is possible that the coin_data_retriever_supervisor crashes
      # and that a new coin is introduced from poloniex after restarting
      # and that the worker for it starts requesting work but doesn't have a history keeper
      # because the coin was later introduced so we make one available for it
      nil ->
        Assignment.HistoryKeeperWorkerSupervisor.add_worker(coin_name)
        GenServer.call(__MODULE__, {:get_pid_for_coin, coin_name})

      pid ->
        pid
    end
  end

  def retrieve_history_processes() do
    GenServer.call(__MODULE__, :retrieve_history_processes)
  end

  # SERVER
  def init([]) do
    {:ok, [], {:continue, :start_history_keeper_workers}}
  end

  def handle_continue(:start_history_keeper_workers, state) do
    if length(DynamicSupervisor.which_children(Assignment.HistoryKeeperWorkerSupervisor)) == 0 do
      Assignment.ProcessManager.retrieve_coin_processes()
      |> Enum.map(&elem(&1, 0))
      |> Enum.each(&Assignment.HistoryKeeperWorkerSupervisor.add_worker(&1))
    end

    {:noreply, state}
  end

  # CALLS
  def handle_call({:get_pid_for_coin, coin_name}, _from, state) do
    pid =
      DynamicSupervisor.which_children(Assignment.HistoryKeeperWorkerSupervisor)
      |> Enum.map(fn {_, pid, _, _} ->
        {Assignment.HistoryKeeperWorker.get_pair_info(pid), pid}
      end)
      |> Enum.find({coin_name, nil}, fn {current_coin_name, _pid} ->
        current_coin_name == coin_name
      end)
      |> elem(1)

    {:reply, pid, state}
  end

  def handle_call(:retrieve_history_processes, _from, state) do
    history_pairs =
      DynamicSupervisor.which_children(Assignment.HistoryKeeperWorkerSupervisor)
      |> Enum.map(fn {_, pid, _, _} ->
        {Assignment.HistoryKeeperWorker.get_pair_info(pid), pid}
      end)

    {:reply, history_pairs, state}
  end
end
