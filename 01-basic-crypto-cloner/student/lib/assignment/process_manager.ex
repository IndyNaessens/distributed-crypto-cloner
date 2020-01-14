defmodule Assignment.ProcessManager do
  @moduledoc """
  This is the ProcessManager module

  This module retrieves/format data from the Coindata.Registry
  """

  ### API ###
  def retrieve_coin_processes() do
    Registry.select(Assignment.Coindata.Registry, [{{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}])
  end

end
