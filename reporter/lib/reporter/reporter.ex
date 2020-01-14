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
    Node.list()
    |> Enum.map(
      &GenServer.call({Assignment.CoindataCoordinator, &1}, :get_history_keeper_worker_statistics)
    )
    |> List.flatten()
    |> Scribe.print(
      data: [
        {"NODE", :node},
        {"COIN", :coin},
        {"PROGRESS (20chars)", :progress_chars},
        {"PROGRESS %", :progress},
        {"# of entries", :entries}
      ]
    )

    Process.send_after(__MODULE__, :render_table, 3000)

    {:noreply, state}
  end
end
