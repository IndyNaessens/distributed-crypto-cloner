defmodule Assignment.HistoryKeeperWorker do
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

  def update_timeframe(pid, %{from: f, until: u}) when is_pid(pid) do
    Agent.update(pid, fn state ->
      Map.replace!(state, :time_frame, %{:from => f, :until => u})
    end)
  end

  def append_to_history(pid, new_history) do
    Agent.update(pid, fn state ->
      Map.update!(state, :history, fn current_history ->
        [new_history | current_history] |> List.flatten()
      end)
    end)
  end
end
