defmodule Assignment.Reporter.Application do

  use Application

  def start(_type, _args) do
    topologies = [
      assignment: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Assignment.ClusterSupervisor]]},
      Assignment.Reporter

    ]

    opts = [strategy: :one_for_one, name: Reporter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
