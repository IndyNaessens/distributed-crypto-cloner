defmodule Assignment.Application do
  use Application

  def start(_type, _args) do
    topologies = [
      assignment: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Assignment.ClusterSupervisor]]},
      Assignment.RateLimiter,
      Assignment.HistoryKeeperSupervisor,
      Assignment.CoindataSupervisor,
      Assignment.CoindataCoordinator
    ]

    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
