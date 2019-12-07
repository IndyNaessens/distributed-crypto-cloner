defmodule Assignment.Application do
  use Application

  def start(_type, _args) do
    children = [
      Assignment.Logger,
      Assignment.RateLimiter,
      Assignment.CoindataSupervisor,
      Assignment.HistoryKeeperSupervisor
    ]

    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
