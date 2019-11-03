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

  def handle_cast({:add_timeframe, timeframe}, state) do
    new_time_frames =
      state
      |> Map.get(:time_frames)
      |> Enum.concat([timeframe])

    {:noreply, Map.replace!(state, :time_frames, new_time_frames)}
  end

  def handle_cast(:work_permission_ok, state) do
    # get time frames
    first_time_frame =
      Map.get(state, :time_frames)
      |> List.first()

    # get current hist
    hist = Map.get(state, :history)

    # do the first timeframe and get the hist
    updated_hist =
      Map.get(state, :coin)
      |> get_history(first_time_frame)
      |> handle_history(first_time_frame)

    # new state
    new_state =
      state
      |> Map.replace!(:history, Enum.concat(hist, updated_hist))
      |> Map.update!(:time_frames, fn lst -> List.delete(lst, first_time_frame) end)

    # change state
    {:noreply, new_state}
  end

  ### INFO ###

  ### HELPERS
  defp get_history(coin_name, %{:from => f, :until => u}) do
    trade_history = AssignmentOne.PoloniexAPiCaller.return_trade_history(coin_name, f, u)
    AssignmentOne.Logger.log("Request finished for coin: #{coin_name}")

    trade_history
  end

  defp get_history(_, _), do: []

  defp handle_history(history, %{:from => from, :until => until})
       when is_list(history) and length(history) == 1000 do
    AssignmentOne.Logger.log("Timeframe too big!")

    # to DateTime
    {:ok, from} = DateTime.from_unix(from)
    {:ok, until} = DateTime.from_unix(until)

    # split timeframe and add it to time_frames
    in_between_dates = DateTime.add(from, div(DateTime.diff(until, from), 2))

    GenServer.cast(
      self(),
      {:add_timeframe,
       %{:from => from |> DateTime.to_unix(), :until => in_between_dates |> DateTime.to_unix()}}
    )

    GenServer.cast(
      self(),
      {:add_timeframe,
       %{:from => in_between_dates |> DateTime.to_unix(), :until => until |> DateTime.to_unix()}}
    )

    # 2 new requests need to be done
    AssignmentOne.RateLimiter.add_worker_request(self())
    AssignmentOne.RateLimiter.add_worker_request(self())

    []
  end

  defp handle_history(history, _) do
    history
  end
end
