defmodule Assignment.CoindataRetriever do
  @moduledoc """
  This is the CoindataRetriever module

  The purpose of this module is to get the trade history for a specifc coin and timeframe
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

    {time_frame_complete, %{:from => f, :until => u}} =
      Assignment.HistoryKeeperWorker.request_timeframe_for_api_call(history_keeper_pid)

    # retrieve trade history, new until date and if the respone was full (1000 elems)
    {history, until, continue} =
      Assignment.PoloniexAPiCaller.return_trade_history(coin_name, f, u)
      |> handle_response({f,u})

    # include retrieved history and update timeframe
    Assignment.HistoryKeeperWorker.append_to_history(history_keeper_pid, history)
    Assignment.HistoryKeeperWorker.update_timeframe_until(history_keeper_pid, until)

    # continue/retry when we don't have the whole tradehistory/when the api gave an error
    if continue == :yes or time_frame_complete == :part,
      do: GenServer.cast(self(), :request_work_permission)

    {:noreply, coin_name}
  end

  ### HELPERS
  defp handle_response(trade_history, _time_frame)
       when is_list(trade_history) and length(trade_history) == 1000 do
    {trade_history, get_last_date_in_trade_history(trade_history), :yes}
  end

  defp handle_response(trade_history, {from, _until}) when is_list(trade_history) do
    {trade_history, from, :no}
  end

  defp handle_response(:poloniex_api_error, {_from,until}) do
    {[], until, :yes}
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
