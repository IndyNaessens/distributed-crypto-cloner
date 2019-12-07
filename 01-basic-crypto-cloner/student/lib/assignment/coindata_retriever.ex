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
    GenServer.start_link(__MODULE__, coin_name)
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
  def handle_cast(:request_work_permission, coin_name) do
    Assignment.RateLimiter.add_request(self())

    {:noreply, coin_name}
  end

  def handle_cast(:work_permission_ok, coin_name) do
    # needed for work (pid, timeframe)
    history_keeper_pid = Assignment.HistoryKeeperManager.get_pid_for(coin_name)

    %{:from => f, :until => u} =
      Assignment.HistoryKeeperWorker.request_timeframe(history_keeper_pid)

    # retrieve trade history, new until date and if the respone was full (1000 elems)
    {history, until, filled} =
      Assignment.PoloniexAPiCaller.return_trade_history(coin_name, f, u)
      |> handle_response()

    # include retrieved history and update timeframe
    Assignment.HistoryKeeperWorker.update_timeframe(history_keeper_pid, %{
      :from => f,
      :until => until
    })

    Assignment.HistoryKeeperWorker.append_to_history(history_keeper_pid, history)

    # if we don't have the whole tradehistory (response -> 1000 elems) ask for a new request
    if filled == :full, do: GenServer.cast(self(), :request_work_permission)
    {:noreply, coin_name}
  end

  ### HELPERS
  defp handle_response(trade_history)
       when is_list(trade_history) and length(trade_history) == 1000 do
    {trade_history, get_last_date_in_trade_history(trade_history), :full}
  end

  defp handle_response(trade_history) when is_list(trade_history) do
    {trade_history, get_last_date_in_trade_history(trade_history), :notfull}
  end

  defp get_last_date_in_trade_history(trade_history) do
    trade_history
    |> List.last()
    |> Map.get("date")
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_unix()
  end
end
