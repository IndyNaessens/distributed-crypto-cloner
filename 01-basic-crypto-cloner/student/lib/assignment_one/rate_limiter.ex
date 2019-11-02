defmodule AssignmentOne.RateLimiter do
  use GenServer

  ### API ###
  def start_link(%{:from => f, :until => u, :req_per_sec => rps}) do
    GenServer.start_link(__MODULE__, %{from: f, until: u, req_per_sec: rps}, name: __MODULE__)
  end

  def change_rate_limit(limit) when is_integer(limit) do
    GenServer.cast(__MODULE__, {:change_rate_limit, limit})
  end

  def current_rate_limit() do
    GenServer.call(__MODULE__, :get_rate_limit)
  end

  def state() do
    GenServer.call(__MODULE__, :state)
  end

  ### SERVER ###
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:change_rate_limit, limit}, state) do
    {:noreply, Map.replace!( state, :req_per_sec, limit )}
  end

  def handle_call(:get_rate_limit, _from, state) do
    {:reply, state |> Map.get(:req_per_sec), state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

end
