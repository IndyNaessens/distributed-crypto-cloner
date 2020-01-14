defmodule Assignment.Reporter do
  use GenServer

  # API
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # SERVER
  def init([]) do
    {:ok, [], {:continue, :start}}
  end

  def handle_continue(:start, state) do
    send(__MODULE__, :render_table)

    {:noreply, state}
  end

  def handle_info(:render_table, state) do
    Assignment.HistoryKeeperManager.retrieve_history_processes()
    |> Enum.map(fn {_coin, pid} -> Assignment.HistoryKeeperWorker.get_statistics(pid) end)
    |> Scribe.print(data: [{"NODE", :node}, {"COIN", :coin}, {"PROGRESS (20chars)", :progress_chars}, {"PROGRESS %", :progress}, {"# of entries", :entries}])

    Process.send_after(__MODULE__, :render_table, 3000)

    {:noreply, state}
  end

end
