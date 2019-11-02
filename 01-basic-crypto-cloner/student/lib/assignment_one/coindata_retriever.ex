defmodule AssignmentOne.CoindataRetriever do
  def get_history(pid) when is_pid(pid) do
    GenServer.call(pid, :coin_hist)
  end
end
