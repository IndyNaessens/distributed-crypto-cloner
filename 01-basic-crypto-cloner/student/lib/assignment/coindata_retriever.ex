defmodule Assignment.CoindataRetriever do
  @moduledoc """
  The purpose of this module is to get the trade history for a specifc coin
  using the Assignment.PoloniexAPiCaller module.

  State of this module:
  coin => The name of the coin we want the trade history from
  time_frame => We want the trade history between 2 specific dates
  history => The trade history

  What will this module mostly do? After requesting work
  permission from the Assignment.RateLimiter, we start
  retrieving the trade history.
  """
  use GenServer

  ### API
  def start_link(coin_name) when is_binary(coin_name) do
    GenServer.start(__MODULE__, coin_name)
  end

  def get_coin_name(pid) when is_pid(pid) do
    GenServer.call(pid, :get_coin_name)
  end

  ### SERVER
  def init(coin_name) do
    {:ok, coin_name}
  end

  ### CALLS ###
  def handle_call(:get_coin_name, _from, coin_name) do
    {:reply, coin_name, coin_name}
  end

  ### CASTS ###
  def handle_cast(:request_work_permission, state) do
    Assignment.RateLimiter.add_request(self())

    {:noreply, state}
  end

  def handle_cast(:work_permission_ok, state) do
    # needed for work
    {coin_name, %{:from => f, :until => u}} = {Map.get(state, :coin), Map.get(state, :time_frame)}

    # retrieve trade history and potential new from date
    {history, until, filled} =
      Assignment.PoloniexAPiCaller.return_trade_history(coin_name, f, u)
      |> handle_response(u)

    # include retrieved history and make timeframe smaller
    new_state =
      state
      |> Map.replace!(:time_frame, %{:from => f, :until => until})
      |> Map.update!(:history, fn current_history ->
        [history | current_history] |> List.flatten()
      end)

    # we don't have the whole tradehistory so ask for a new request
    if filled == :full, do: GenServer.cast(self(), :request_work_permission)
    {:noreply, new_state}
  end

  ### INFO ###

  ### HELPERS
  defp handle_response(trade_history, _until)
       when is_list(trade_history) and length(trade_history) == 1000 do
    until =
      trade_history
      |> List.last()
      |> Map.get("date")
      |> NaiveDateTime.from_iso8601!()
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix()

    {trade_history, until, :full}
  end

  defp handle_response(trade_history, until) when is_list(trade_history),
    do: {trade_history, until, :notfull}
end
