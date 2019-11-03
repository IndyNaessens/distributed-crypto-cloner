defmodule AssignmentOne.Startup do
  require IEx

  defstruct req_per_sec: 5

  def start_link(args \\ []),
    do: {:ok, spawn_link(__MODULE__, :startup, [struct(__MODULE__, args)])}

  def startup(_info) do
    # Implement this module
    AssignmentOne.Logger.start_link()
    # Implement this module
    AssignmentOne.ProcessManager.start_link()
    # Implement this module
    AssignmentOne.RateLimiter.start_link()

    retrieve_coin_pairs() |> start_processes()

    keep_running_until_stopped()
  end

  defp retrieve_coin_pairs() do
    AssignmentOne.PoloniexAPiCaller.return_ticker()
    |> Map.keys()
  end

  defp start_processes(pairs) when is_list(pairs) do
    pairs
    |> Enum.each(&AssignmentOne.ProcessManager.start_coin_process(&1))

    AssignmentOne.ProcessManager.send_request_to_all(:request_work_permission)
  end

  defp keep_running_until_stopped() do
    receive do
      :stop -> Process.exit(self(), :normal)
    end
  end
end
