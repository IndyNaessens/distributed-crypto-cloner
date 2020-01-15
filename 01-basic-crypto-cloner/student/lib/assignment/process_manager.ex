defmodule Assignment.ProcessManager do
  @moduledoc """
  This is the ProcessManager module

  This module retrieves/format data from the Coindata.Registry
  """

  ### API ###
  def get_pid_for(coin_name) when is_binary(coin_name) do
    Registry.lookup(Assignment.Coindata.Registry, coin_name)
    |> List.first()
    |> elem(0)
  end

  def retrieve_coin_processes() do
    Registry.select(Assignment.Coindata.Registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

end
