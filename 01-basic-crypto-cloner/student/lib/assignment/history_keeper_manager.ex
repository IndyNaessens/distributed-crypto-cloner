defmodule Assignment.HistoryKeeperManager do

  # API
  def get_pid_for(coin_name) when is_binary(coin_name) do
    retrieve_history_processes()
    |> Enum.find(fn {current_coin_name, _pid} -> current_coin_name == coin_name end)
    |> elem(1)
  end

  def retrieve_history_processes() do
    DynamicSupervisor.which_children(Assignment.HistoryKeeperWorkerSupervisor)
    |> Enum.map(fn {_, pid, _, _} ->
      {Assignment.HistoryKeeperWorker.get_pair_info(pid), pid}
    end)
  end

  def start_history_keepers(currency_pairs) do
    currency_pairs
    |> Enum.map(&elem(&1, 0))
    |> Enum.each(&Assignment.HistoryKeeperWorkerSupervisor.add_worker(&1))
  end
end
