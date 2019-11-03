defmodule AssignmentOne.CoindataRetriever do
  use GenServer

  @from (DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 7
  @until DateTime.utc_now() |> DateTime.to_unix()

  @default_time_frame %{:from => @from, :until => @until}

  ### API
  def start(coin_name) when is_binary(coin_name) do
    GenServer.start(__MODULE__, %{
      :coin => coin_name,
      :time_frames => [@default_time_frame],
      :history => []
    })
  end

  def get_history(pid) when is_pid(pid) do
    GenServer.call(pid, :coin_history)
  end

  ### SERVER
  def init(state) do
    {:ok, state}
  end

  ### CALLS ###
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:coin_history, _from, state) do
    coin_hist = {
      Map.get(state, :coin),
      Map.get(state, :history)
    }

    {:reply, coin_hist, state}
  end

  ### CASTS ###
  def handle_cast(:request_work_permission, state) do
    AssignmentOne.RateLimiter.add_worker_request(self())

    {:noreply, state}
  end

  def handle_cast(:work_permission_ok, state) do
    # get time frames
    [first_time | other_times] = Map.get(state, :time_frames)

    # get current hist
    hist = Map.get(state, :history)

    # do the first timeframe and get the hist
    updated_hist =
      Map.get(state, :coin)
      |> do_work(first_time)

    # new state
    new_state =
      state
      |> Map.replace!(:history, hist ++ updated_hist)
      |> Map.replace!(:time_frames, other_times)

    # change state
    {:noreply, new_state}
  end

  ### INFO ###

  ### HELPERS
  defp do_work(coin_name, %{:from => f, :until => u}) do
    AssignmentOne.PoloniexAPiCaller.return_trade_history(coin_name, f, u)
    AssignmentOne.Logger.log("Request finished for coin: #{coin_name}")
  end
end
