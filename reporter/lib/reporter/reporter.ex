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
    table_data =
    Node.list()
    |> Enum.map(
      &GenServer.call(:global.whereis_name({&1, Assignment.CoindataCoordinator}), :get_history_keeper_worker_statistics)
    )
    |> List.flatten()
    |> Enum.sort_by(&Map.get(&1, :progress), &>=/2)

    IEx.Helpers.clear()
    Scribe.print(table_data,
      data: [
        {"NODE", :node},
        {"COIN", :coin},
        {"PROGRESS (20chars)", :progress_chars},
        {"PROGRESS %", :progress_percent},
        {"# of entries", :entries}
      ]
    )
    IO.puts("Total of #{table_data |> length} entries")
    Process.send_after(__MODULE__, :render_table, 2000)

    {:noreply, state}
  end

end
