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

  ### API ###
  def retrieve_coin_processes() do
    DynamicSupervisor.which_children(Assignment.CoindataRetrieverSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      {Assignment.CoindataRetriever.get_coin_name(pid), pid}
    end)
  end

  def start_coin_data_retrievers(currency_pairs) do
    currency_pairs
    |> Map.keys()
    |> Enum.each(&Assignment.CoindataRetrieverSupervisor.add_worker(&1))
  end

  def start_work() do
    DynamicSupervisor.which_children(Assignment.CoindataRetrieverSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      GenServer.cast(pid, :request_work_permission)
    end)
  end
end
