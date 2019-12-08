defmodule Assignment.ProcessManager do
  @moduledoc """
  This is the ProcessManager module

  It starts CoindataRetrievers using a DynamicSupervisor
  After they are started we can call this module instead of the DynamicSupervisor
  for data
  """
  use GenServer

  ### API ###
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def retrieve_coin_processes() do
    GenServer.call(__MODULE__, :retrieve_coin_processes)
  end

  def start_work() do
    GenServer.cast(__MODULE__, :start_work)
  end

  # SERVER
  def init([]) do
    {:ok, [], {:continue, :start_coin_data_workers}}
  end

  def handle_continue(:start_coin_data_workers, state) do
    if length(DynamicSupervisor.which_children(Assignment.CoindataRetrieverSupervisor)) == 0 do
      Assignment.PoloniexAPiCaller.return_ticker()
      |> Map.keys()
      #|> Enum.take(3)
      |> Enum.each(&Assignment.CoindataRetrieverSupervisor.add_worker(&1))
    end

    {:noreply, state}
  end

  # CALLS
  def handle_call(:retrieve_coin_processes, _from, state) do
    coin_pairs =
      DynamicSupervisor.which_children(Assignment.CoindataRetrieverSupervisor)
      |> Enum.map(fn {_, pid, _, _} ->
        {Assignment.CoindataRetriever.get_coin_name(pid), pid}
      end)

    {:reply, coin_pairs, state}
  end

  # CASTS
  def handle_cast(:start_work, state) do
    DynamicSupervisor.which_children(Assignment.CoindataRetrieverSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      GenServer.cast(pid, :request_work_permission)
    end)

    {:noreply, state}
  end
end
