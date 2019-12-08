defmodule Assignment.HistoryKeeperWorker do
  @moduledoc """
  This is the HistoryKeeperWorker module

  The CoinDataRetriever module uses this module to store the retrieved history
  It uses an Agent to hold/update the following state
  - coin_name (string/binary)
  - time_frame (time frame of the history we want to keep)
      This time_frame becomes smaller (until comes closer to from) when we the CoinDataRetrievers retrieve the history
      This is because PoloniexApiCaller can't return the history in 1 call because the api has a max of 1000 trades
      it can return, so we need to adjust our timeframe hence it becomes smaller over time
  - history (trade history for the specified coin_name)
  """
  use Agent

  # API
  def start_link(coin_name) do
    Agent.start_link(fn ->
      %{
        :coin => coin_name,
        :time_frame => %{
          :from => Application.fetch_env!(:assignment, :from),
          :until => Application.fetch_env!(:assignment, :until)
        },
        :history => []
      }
    end)
  end

  def get_history(pid) when is_pid(pid) do
    Agent.get(pid, fn state ->
      {
        Map.get(state, :coin),
        Map.get(state, :history)
      }
    end)
  end

  def get_pair_info(pid) when is_pid(pid) do
    Agent.get(pid, fn state -> Map.get(state, :coin) end)
  end

  def request_timeframe(pid) when is_pid(pid) do
    Agent.get(pid, fn state -> Map.get(state, :time_frame) end)
  end

  @doc """
  Method that gives a time frame that is valid for the Poloniex api
  """
  def request_timeframe_for_api_call(pid) when is_pid(pid) do
    Agent.get(pid, fn state ->
      Map.get(state, :time_frame)
      |> transform_time_frame()
    end)
  end

  defp transform_time_frame(%{:from => from, :until => until}) do
    amount_of_days = Float.ceil((until - from) / 86400)

    cond do
      amount_of_days > 30 -> {:part, %{:from => until - 60 * 60 * 24 * 30, :until => until}}
      true -> {:complete, %{:from => from, :until => until}}
    end
  end

  def update_timeframe(pid, %{from: f, until: u}) when is_pid(pid) do
    Agent.update(pid, fn state ->
      Map.replace!(state, :time_frame, %{:from => f, :until => u})
    end)
  end

  def update_timeframe_until(pid, until) do
    Agent.update(pid, fn state ->
      Map.update!(state, :time_frame, fn time_frame ->
        Map.replace!(time_frame, :until, until)
      end)
    end)
  end

  def append_to_history(pid, new_history) when is_pid(pid) and is_list(new_history) do
    Agent.update(pid, fn state ->
      Map.update!(state, :history, fn current_history ->
        [new_history |> Enum.reverse() | current_history] |> List.flatten()
      end)
    end)
  end
end
