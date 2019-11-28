defmodule Assignment.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Do not change this file!
      %{
        id: Assignment.Startup,
        start: {Assignment.Startup, :start_link, []}
      }
    ]

    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
