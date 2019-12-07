# Permanent Evaluation 3: Distributed cloner with reporter

## Rules

Your code will need to be submitted through GitHub Classroom.

The deadline for committing your code is `[VERIFY] Wednesday 15 January at 23:59`. Starting from Thursday 16 January 00:00, a script will clone your repository with your solution.

__File creation/last edit time is of no relevance at all for this deadline! Your code should be online at this moment in time.__

If for some mysterious reason GitHub should be offline, you are allowed to send it by mail. GitHub uptime will also be monitored.

_This might be obvious, but not having internet access is by no means a reason to not submit your code before the deadline._

There can be small changes to this assignment (function names, small adjustments, etc...).

## Assignment

For this assignment, you will need to refactor your second iterations
so as to include load balancing. The logger must also be replaced by
a separate reporter application.

## Sample flow of application

Feel free to make the assumption that you'll always start a cloner node before you start a reporter node

* Node 1 is started
* Node 1 detects no other nodes and starts cloning
* Node 2 is started
* Node 2 detects other nodes and it doesn't start cloning automatically
* Node 3 is started
* Node 3 detects other nodes and it doesn't start cloning automatically
* Node 2 starts balancing
* Node 2 asks node 1 to transfer N currency pairs to node 3
* Node 2 asks node 1 to transfer N currency pairs to node 2
* Reporter is started
* Every 10 seconds output is printed on that node's CLI
* Node 3 quits and N currency pairs are lost
* Node 2 starts balancing
* Node 2 detects that not all currency pairs are being cloned, and starts processes the missing currency pairs
* Node 2 asks Node X to transfer N currency pairs to node X

## Reporter Application

This is a simple application with no globally registered processes. It has one `GenServer` that runs the necessary code every 10 seconds to print out the status of the whole distributed application.

I'm expecting easy to read,  **sorted** (based on %) output such as:

```text
NODE | COIN     | PROGRESS (20chars)   | PROGRESS % | # of entries
##################################################################
N1   | USDT_BTC | ___________________+ | 5%         | 900
N2   | USDT_XMR | __________________++ | 10%        | 500
N4   | ...      | _____________+++++++ | 35%        | 20
N3   | ...      | __________++++++++++ | 50%        | 60
N4   | ...      | ++++++++++++++++++++ | 100%       | 40
N2   | ...      | ++++++++++++++++++++ | 100%       | 112
```

## Registry module

It is up to you to use either:

* 1 application registry where you work with the keys "coindata" and "historykeeper". The values for these groups are a list of tuples, where one tuple is an entry for a worker.
  * Easier to use for local PubSub mechanisms.
  * Easier to use for retrieving all pids of a single group.
  * Difficult to do specific key-value lookups. (Registry.match or Registry.select)
* 2 registries for each "group" or purpose. e.g. `Assignment.Coindata.Registry` and `Assignment.HistoryKeeper.Registry`.
  * Easier to do key-value lookups (`Registry.lookup`)
  * Difficult to retrieve all pids. Documentation explains this at `Registry.select` (`SelectAllTest`).

At the exam, I will ask which method you chose and your reasons why.

## Evaluation

* There will be no tests, but on the exam you'll thoroughly show how your application works in 10 minutes.

## Requirements

You need to refactor your code and implement additional features as listed below.

* Process manager is replaced with the built-in registry module (more about this later.)
* History keeper manager is replaced with the built-in registry module (more about this later.)
* You'll still use application configuration for the `:rate`, `:from` and `:until` values.
* You no longer need a logger in your cloner application. (_Hint: delete this functionality at the last moment so that you can use this to verify that other functionalities work._)
* You'll create a second application, which is your "reporter" application. More about this later.
* When a node joins the cluster (use libcluster), it is automatically connected to the other nodes.
* Upon joining the cluster, you check whether other nodes are in the cluster or not. (If not, you're the first node in the cluster.) If there are other nodes, you do not automatically start cloning. If you are the first node, then you start all currency pair processes.
* Up until now you have no globally registered processes. Since your process manager is gone, you'll need another process to do some kind "balancing" between nodes (more about this later). Create a globally registered process with the module name `Assignment.CoindataCoordinator`.
* At each moment in time, a node can rebalance work over the cluster. You do this with `Assignment.CoindataCoordinator.balance/0`. This balancing algorithm does not need to be optimal, but should be eventually consistend after running several times.
* When work is redistributed, progress is **NOT** lost.
* When a node crashes, do not worry about no longer cloning all the currency pairs.
* When calling the `Assignment.CoindataCoordinator.balance/0` function, it'll check with the REST API if the application is running all the necessary processes to clone all currency pairs. If there are missing processes (e.g. because of a node disconnecting), you'll start these under your own node (because they'll be balanced anyway).
