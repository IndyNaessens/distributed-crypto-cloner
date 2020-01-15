defmodule Assignment.CoindataCoordinator do
  use GenServer

  # API
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_coin(coin_name) when is_binary(coin_name) do
    GenServer.cast(__MODULE__, {:add_coin, coin_name})
  end

  def add_coin(coin_name, history_keeper_worker_state)
      when is_map(history_keeper_worker_state) and is_binary(coin_name) do
    GenServer.cast(__MODULE__, {:add_coin, coin_name, history_keeper_worker_state})
  end

  def get_history_keeper_worker_statistics() do
    GenServer.call(__MODULE__, :get_history_keeper_worker_statistics)
  end

  def get_history_keeper_worker_statistic(coin_name) do
    GenServer.call(__MODULE__, {:get_history_keeper_worker_statistic, coin_name})
  end

  def get_hist_keeper_coin_pairs() do
    GenServer.call(__MODULE__, :get_hist_keeper_coin_pairs)
  end

  @doc """
  Transfers a HistoryKeeperWorker and CoindataRetriever responsible for the given coin_name
  from the current node to the node_to
  """
  def transfer_coin(coin_name, node_to) do
    GenServer.cast(__MODULE__, {:transfer_coin, coin_name, node_to})
  end

  def balance() do
    GenServer.cast(__MODULE__, :balance)
  end

  # SERVER
  def init([]) do
    {:ok, [], {:continue, :continue}}
  end

  def handle_continue(:continue, state) do
    # check how many cloner nodes are in the cluster
    # expects the short name of the reporter node to contain "reporter"
    amount_of_cloner_nodes =
      Node.list()
      |> Enum.filter(
        &(Atom.to_string(&1) |> String.downcase() |> String.contains?("reporter") == false)
      )
      |> length

    # when we have zero cloner nodes, start cloning as first node
    if amount_of_cloner_nodes == 0 do
      Assignment.PoloniexAPiCaller.return_ticker()
      |> Map.keys()
      #|> Enum.take(30)
      |> Enum.each(&add_coin(&1))
    end

    {:noreply, state}
  end

  def handle_cast(:balance, state) do
    # nodes without ourself
    nodes =
      Node.list()
      # only get worker nodes
      |> Enum.filter(
        &(Atom.to_string(&1) |> String.downcase() |> String.contains?("reporter") == false)
      )

    # all nodes, ourself included (no reporter)
    nodes_all = [Node.self(), nodes] |> List.flatten()

    coins_being_handled =
      nodes
      # for each node get a list of the coin pairs for the history keeper workers
      |> Enum.map(fn node ->
        {node,
         GenServer.call({Assignment.CoindataCoordinator, node}, :get_hist_keeper_coin_pairs)}
      end)
      # include ourself
      |> Enum.concat(Assignment.HistoryKeeperManager.retrieve_history_processes())
      # map to {node, coin} so we now which node handles wich coin
      |> Enum.map(fn {node, list} -> Enum.map(list, fn pair -> {node, elem(pair, 0)} end) end)
      # flatten the list so we have 1 list instead of N node lists in a list
      |> List.flatten()

    # we want all supported coins from the rest service
    unhandeled_coins =
      Assignment.PoloniexAPiCaller.return_ticker()
      |> Map.keys()
      # we only want the coins that are not present in the handled coins
      |> Enum.filter(
        &(!Enum.member?(coins_being_handled |> Enum.map(fn pair -> elem(pair, 1) end), &1))
      )
      # map it to the right format {node, coin} (node becomes nil because it's not handled by any node)
      |> Enum.map(&{nil, &1})

    # combine both lists so we have a nice overview of which coin is handled by wich node or if it's not handled by any node
    combined_list = [coins_being_handled | unhandeled_coins] |> List.flatten()

    # zip it so we know wich coin is going to wich new node
    # we get a list if this type {{node, coin}, new_node}
    # we do +1 because if we have 92 coins and 3 nodes, div(92,3) is 30
    # if we duplicate a list of 3 nodes 30 times and flatten it we have a list of 90 items
    # but we have 92 coins so we do +1 so we have 93 items and then zip it the last one doesn't matter
    # because zip finishes when any enumarable completes and the combined list completes first
    combined_list
    # sort on progress for the balancing
    |> Enum.sort_by(fn {node_from, coin_name} ->
      cond do
        node_from == Node.self() ->
          Assignment.HistoryKeeperManager.get_pid_for(coin_name)
          |> Assignment.HistoryKeeperWorker.get_statistics()
          |> Map.get(:progress)

        node_from != nil ->
          GenServer.call(
            {Assignment.CoindataCoordinator, node_from},
            {:get_history_keeper_worker_statistic, coin_name}
          )
          |> Map.get(:progress)

        true ->
          0.00
      end
    end)
    |> Enum.zip(
      List.duplicate(nodes_all, div(combined_list |> length, nodes_all |> length) + 1)
      |> List.flatten()
    )
    # do the balancing
    # if the coin is being handled by a node, transfer it
    # if the coin is not handled by a node, start it
    |> Enum.each(fn coin_info_for_balancing ->
      case coin_info_for_balancing do
        {{nil, coin_name}, node_to} ->
          GenServer.cast({Assignment.CoindataCoordinator, node_to}, {:add_coin, coin_name})

        {{node_from, coin_name}, node_to} ->
          GenServer.cast(
            {Assignment.CoindataCoordinator, node_from},
            {:transfer_coin, coin_name, node_to}
          )
      end
    end)

    {:noreply, state}
  end

  def handle_cast({:add_coin, coin_name}, state) do
    # start the workers
    Assignment.HistoryKeeperWorkerSupervisor.add_worker(coin_name)
    Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)

    {:noreply, state}
  end

  def handle_cast({:add_coin, coin_name, history_keeper_worker_state}, state) do
    # start the workers
    Assignment.HistoryKeeperWorkerSupervisor.add_worker(history_keeper_worker_state)
    Assignment.CoindataRetrieverSupervisor.add_worker(coin_name)

    {:noreply, state}
  end

  def handle_cast({:transfer_coin, coin_name, node_to}, state) do
    # get retriever and keeper pid
    {retriever_pid, keeper_pid} =
      {Assignment.ProcessManager.get_pid_for(coin_name),
       Assignment.HistoryKeeperManager.get_pid_for(coin_name)}

    # get state frrom historykeeper
    state_from_keeper = Assignment.HistoryKeeperWorker.get_state(keeper_pid)

    # stop retriever and keeper
    GenServer.stop(retriever_pid)
    GenServer.stop(keeper_pid)

    # start keeper with state and start retriever on new node
    GenServer.cast(
      {Assignment.CoindataCoordinator, node_to},
      {:add_coin, coin_name, state_from_keeper}
    )

    {:noreply, state}
  end

  def handle_call(:get_hist_keeper_coin_pairs, _from, state) do
    {:reply, Assignment.HistoryKeeperManager.retrieve_history_processes(), state}
  end

  def handle_call(:get_history_keeper_worker_statistics, _from, state) do
    pairs =
      Assignment.HistoryKeeperManager.retrieve_history_processes()
      |> Enum.map(fn {_coin, pid} -> Assignment.HistoryKeeperWorker.get_statistics(pid) end)

    {:reply, pairs, state}
  end

  def handle_call({:get_history_keeper_worker_statistic, coin_name}, _from, state) do
    {:reply,
     Assignment.HistoryKeeperManager.get_pid_for(coin_name)
     |> Assignment.HistoryKeeperWorker.get_statistics(), state}
  end
end
