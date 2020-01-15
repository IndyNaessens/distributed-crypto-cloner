defmodule Assignment.HistoryKeeperWorker do
  @moduledoc """
  This is the HistoryKeeperWorker module

  The CoinDataRetriever module uses this module to store the retrieved history
  It uses an Agent to hold/update the following state
  - coin_name (string/binary)
  - :reference_time_frame
      This time_frame is used to calculate progress. How much of the time frame is already complete?
      In other words this is the original time frame
  - time_frame (time frame of the history we want to keep)
      This time_frame becomes smaller (until comes closer to from) when we the CoinDataRetrievers retrieve the history
      This is because PoloniexApiCaller can't return the history in 1 call because the api has a max of 1000 trades
      it can return, so we need to adjust our timeframe hence it becomes smaller over time
  - history (trade history for the specified coin_name)
  """
  use Agent, restart: :transient

  # API
  def start_link(coin_name) when is_binary(coin_name) do
    Agent.start_link(
      fn ->
        %{
          :coin => coin_name,
          :reference_time_frame => %{
            :from => Application.fetch_env!(:assignment, :from),
            :until => Application.fetch_env!(:assignment, :until)
          },
          :time_frame => %{
            :from => Application.fetch_env!(:assignment, :from),
            :until => Application.fetch_env!(:assignment, :until)
          },
          :history => []
        }
      end,
      name: {:via, Registry, {Assignment.HistoryKeeper.Registry, coin_name}}
    )
  end

  def start_link(state) when is_map(state) do
    Agent.start_link(fn -> state end,
      name: {:via, Registry, {Assignment.HistoryKeeper.Registry, Map.get(state, :coin)}}
    )
  end

  def get_state(pid) do
    Agent.get(pid, fn state -> state end)
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

    Agent.update(pid, fn state ->
      Map.replace!(state, :reference_time_frame, %{:from => f, :until => u})
    end)
  end

  @doc """
  Used for progress
  """
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

  def get_statistics(pid) do
    # get time diff from ref_time_frame
    reference_time_frame = Agent.get(pid, fn state -> Map.get(state, :reference_time_frame) end)

    reference_time_diff =
      DateTime.diff(
        Map.get(reference_time_frame, :until) |> DateTime.from_unix!(),
        Map.get(reference_time_frame, :from) |> DateTime.from_unix!()
      )

    # get time diff from time_frame
    time_frame = Agent.get(pid, fn state -> Map.get(state, :time_frame) end)

    time_diff =
      DateTime.diff(
        Map.get(time_frame, :until) |> DateTime.from_unix!(),
        Map.get(time_frame, :from) |> DateTime.from_unix!()
      )

    # calc progress in % and chars
    progress = ((1 - time_diff / reference_time_diff) * 100) |> Float.round(2)
    progress_chars = (progress / 5) |> Float.floor() |> Kernel.trunc()

    # put the stats in a map for ease of display
    Agent.get(pid, fn state ->
      %{
        :node => Node.self() |> Atom.to_string() |> String.split("@") |> List.first(),
        :coin => Map.get(state, :coin),
        :entries => Map.get(state, :history) |> length(),
        :progress => progress,
        :progress_percent => "#{progress}%",
        :progress_chars =>
          "#{String.duplicate("_", 20 - progress_chars)}#{String.duplicate("+", progress_chars)}"
      }
    end)
  end
end
