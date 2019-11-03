defmodule AssignmentOne.CoindataRetriever do
  @moduledoc """
  The purpose of this module is to get the trade history for a specifc coin
  using the AssignmentOne.PoloniexAPiCaller module.

  State of this module:
  coin => The name of the coin we want the trade history from
  time_frames => We want the trade history between 2 specific dates
  history => The trade history

  What will this module mostly do? After requesting work
  permission from the AssignmentOne.RateLimiter, we start
  retrieving the trade history for the first timeframe
  in our time_frames.

  So why is time_frames a list? Well the API we are using can only return
  a maximum of 1000 trades for a specific timeframe. So when we request a
  timeframe and get the max back we will split that timeframe and keep both
  timeframes so we know that we don't have the history for those timeframes

  Look at the function ´handle_history/2´ as an example of the above.

  When the ratelimiter gives us permission to work we will take the earliest timeframe
  and request the trade history for the coin with that timeframe
  """

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
    # get earliest timeframe
    first_time_frame =
      Map.get(state, :time_frames)
      |> Enum.min_by(&Map.get(&1, :from))

    # get current hist
    hist = Map.get(state, :history)

    # do the first timeframe and get the hist
    updated_hist =
      Map.get(state, :coin)
      |> get_history(first_time_frame)
      |> handle_history(first_time_frame, Map.get(state, :coin))

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

  defp handle_history(history, %{:from => from, :until => until}, coin)
       when is_list(history) and length(history) == 1000 do
    AssignmentOne.Logger.log("Timeframe too big for the coin: #{coin}")

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

  defp handle_history(history, _, _) do
    history
  end
end
