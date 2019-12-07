defmodule Assignment.CoindataRetrieverSupervisor do
  use DynamicSupervisor

  # API
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :no_args, name: __MODULE__)
  end

  def add_worker(coin_name) do
    spec = {Assignment.CoindataRetriever, coin_name}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  # SERVER
  def init(:no_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
