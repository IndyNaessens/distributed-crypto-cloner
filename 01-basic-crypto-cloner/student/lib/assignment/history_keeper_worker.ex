defmodule Assignment.HistoryKeeperWorker do
  use Agent

  @from (DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 1
  @until DateTime.utc_now() |> DateTime.to_unix()

  @default_time_frame %{:from => @from, :until => @until}

  # API
  def start_link(coin_name) do
    Agent.start_link(fn ->
      %{
        :coin => coin_name,
        :time_frame => @default_time_frame,
        :history => []
      }
    end)
  end

  def get_history(pid) when is_pid(pid) do
  end

  def get_pair_info(pid) when is_pid(pid) do
  end

  def request_timeframe(pid) when is_pid(pid) do
  end

  def update_timeframe(pid, %{from: _, until: _}) when is_pid(pid) do
  end
end
