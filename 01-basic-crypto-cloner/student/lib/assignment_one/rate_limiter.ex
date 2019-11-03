defmodule AssignmentOne.RateLimiter do
  use GenServer

  @default_rate_limit 5

  ### API ###
  def start_link() do
    GenServer.start_link(
      __MODULE__,
      %{:req_per_sec => @default_rate_limit, :worker_requests => []},
      name: __MODULE__
    )

    send(__MODULE__, :handle_queue)
  end

  def change_rate_limit(limit) when is_integer(limit) do
    GenServer.cast(__MODULE__, {:change_rate_limit, limit})
  end

  def current_rate_limit() do
    GenServer.call(__MODULE__, :get_rate_limit)
  end

  def worker_requests() do
    GenServer.call(__MODULE__, :worker_requests)
  end

  def add_worker_request(pid) when is_pid(pid) do
    GenServer.cast(__MODULE__, {:add_worker_request, pid})
  end

  def state() do
    GenServer.call(__MODULE__, :state)
  end

  ### SERVER ###
  def init(state) do
    {:ok, state}
  end

  ### CALLS ###
  def handle_call(:get_rate_limit, _from, state) do
    {:reply, Map.get(state, :req_per_sec), state}
  end

  def handle_call(:worker_requests, _from, state) do
    {:reply, Map.get(state, :worker_requests), state}
  end

  def handle_call(:handle_queue, _from, state) do
    # get queue
    new_queue =
      state
      |> Map.get(:worker_requests)
      |> List.pop_at(0)

    # notify worker
    new_queue
    |> elem(0)
    |> notify_worker()

    # return req/sec and update state
    {:reply, Map.get(state, :req_per_sec),
     Map.replace!(state, :worker_requests, elem(new_queue, 1))}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  ### CASTS ###
  def handle_cast({:add_worker_request, pid}, state) do
    queue =
      state
      |> Map.get(:worker_requests)

    {:noreply, Map.replace!(state, :worker_requests, Enum.concat(queue, [pid]))}
  end

  def handle_cast({:change_rate_limit, limit}, state) do
    {:noreply, Map.replace!(state, :req_per_sec, limit)}
  end

  ### INFO ###
  def handle_info(:handle_queue, state) do
    pid =
      state
      |> Map.get(:worker_requests)
      |> List.first()

    notify_worker(pid)

    Process.send_after(
      __MODULE__,
      :handle_queue,
      div(1000, Map.get(state, :req_per_sec, @default_rate_limit))
    )

    {:noreply, Map.update!(state, :worker_requests, fn lst -> List.delete(lst, pid) end)}
  end

  ### HELPERS ###
  defp notify_worker(pid) when is_pid(pid), do: GenServer.cast(pid, :work_permission_ok)
  defp notify_worker(_), do: nil
end
