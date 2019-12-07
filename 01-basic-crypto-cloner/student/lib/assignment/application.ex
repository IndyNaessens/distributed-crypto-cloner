defmodule Assignment.Application do
  use Application

  def start(_type, _args) do
    children = [
      Assignment.Logger,
      Assignment.RateLimiter,
      Assignment.HistoryKeeperWorkerSupervisor,
      Assignment.CoindataRetrieverSupervisor,
      {Task,
       fn ->
         currency_pairs = Assignment.PoloniexAPiCaller.return_ticker()

         task_one =
           Task.async(fn ->
             Assignment.ProcessManager.start_coin_data_retrievers(currency_pairs)
           end)

         task_two =
           Task.async(fn ->
             Assignment.HistoryKeeperManager.start_history_keepers(currency_pairs)
           end)

         Task.await(task_one)
         Task.await(task_two)

         Assignment.ProcessManager.start_work()
       end}
    ]

    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
