defmodule Assignment.CoindataRetrieverSupervisor do
  @moduledoc """
  This is the CoindataRetrieverSupervisor module

  It's a DynamicSupervisor that supervises n-amount CoindataRetrievers
  It uses a one_for_one strategy
  """
  use DynamicSupervisor

  # API
  def start_link([]) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_worker(coin_name) do
    spec = {Assignment.CoindataRetriever, coin_name}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  # SERVER
  def init([]) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
