defmodule Assignment.RateLimiter do
  @moduledoc """
  A simple rate limiter that talks with CoindataRetriever processes.

  State:
  req_per_sec => The amount of requests that can be done in a second
  request_queue => A queue of pids that want to do a request.

  This module will have a queue of pids that
  have asked the rate limiter if they can send a request. The
  rate limiter will give each process the permission to start
  a request by sending the process a message.

  This will be done while respecting the amount of requests
  that can be send in a second (req_per_sec).
  """
  use GenServer

  ### API ###
  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      nil,
      name: __MODULE__
    )
  end

  def change_rate_limit(limit) when is_integer(limit) do
    GenServer.cast(__MODULE__, {:change_rate_limit, limit})
  end

  def current_rate_limit() do
    GenServer.call(__MODULE__, :get_rate_limit)
  end

  def request_queue() do
    GenServer.call(__MODULE__, :request_queue)
  end

  def add_request(pid) when is_pid(pid) do
    GenServer.cast(__MODULE__, {:add_request, pid})
  end

  ### SERVER ###
  def init(_) do
    {:ok, nil, {:continue, :start_queue_handling}}
  end

  def handle_continue(:start_queue_handling, _state) do
    send(__MODULE__, :handle_queue)
    state = %{:req_per_sec => Application.fetch_env!(:assignment, :rate), :request_queue => :queue.new()}

    {:noreply, state}
  end

  ### CALLS ###
  def handle_call(:get_rate_limit, _from, state) do
    {:reply, Map.get(state, :req_per_sec), state}
  end

  def handle_call(:request_queue, _from, state) do
    {:reply, Map.get(state, :request_queue), state}
  end

  ### CASTS ###
  def handle_cast({:add_request, pid}, state) do
    new_state =
      state
      |> Map.update!(:request_queue, &:queue.in(pid, &1))

    {:noreply, new_state}
  end

  def handle_cast({:change_rate_limit, limit}, state) do
    {:noreply, Map.replace!(state, :req_per_sec, limit)}
  end

  ### INFO ###
  def handle_info(:handle_queue, state) do
    new_queue =
      state
      |> Map.get(:request_queue)
      |> :queue.out()
      |> grant_permission()

    Process.send_after(
      __MODULE__,
      :handle_queue,
      div(1000, Map.get(state, :req_per_sec, 5))
    )

    {:noreply, Map.replace!(state, :request_queue, new_queue)}
  end

  ### HELPERS ###
  defp grant_permission({{:value, pid}, queue}) when is_pid(pid) do
    GenServer.cast(pid, :work_permission_ok)
    queue
  end

  defp grant_permission({:empty, queue}), do: queue
end
