defmodule Assignment.HistoryKeeperManager do
  @moduledoc """
  This is the HistoryKeeperManager module

  This module retrieves/format data from the HistoryKeeper.Registry
  """

  # API
  def get_pid_for(coin_name) when is_binary(coin_name) do
    Registry.lookup(Assignment.HistoryKeeper.Registry, coin_name)
    |> List.first()
    |> elem(0)
  end

  def retrieve_history_processes() do
    Registry.select(Assignment.HistoryKeeper.Registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

end
