# Permanent Evaluation 2 : fault-tolerant API consuming service

## Rules

Your code will need to be submitted through GitHub Classroom.

The deadline for committing your code is `Sunday 8 December at 23:59`. Starting from Monday 9 December 00:00, a script will clone your repository with your solution.

__File creation/last edit time is of no relevance at all for this deadline! Your code should be online at this moment in time.__

If for some mysterious reason GitHub should be offline, you are allowed to send it by mail. GitHub uptime will also be monitored.

_This might be obvious, but not having internet access is by no means a reason to not submit your code before the deadline._

There can be small changes to this assignment (function names, small adjustments, etc...).

## Assignment

You will refactor your code and implement new features written below.

Requirements:

* The startup file should no longer exist.
* Use the application configuration to configure:
  * This configuration should be stored under root_folder/config/config.exs
  * [Relevant documentation](https://hexdocs.pm/elixir/Config.html)
  * Your timeframe (previously `@from` and `@until` module attributes in the startup file.)
  * The api request/s limit.
* The configuration file must contain the following settings:
  * `:until` must be set to `DateTime.utc_now() |> DateTime.to_unix()`
  * `:from` must be set to `(DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 33`
  * `:rate` must be set to `5`
* For the part regarding your process manager and worker processes:
  * Use an appropriate supervisor construction for your process manager and worker processes.
  * Your process manager is allowed to crash as long as it does not impact the rest of your application.
  * The process manager name registration stays the same.
  * Use a supervisor that supports dynamic workers out of the box and name-register this as `Assignment.CoindataRetrieverSupervisor`.
  * Worker processes (`Assignment.CoindataRetriever` processes) are started in the process manager.
  * By no means should the "starting processes" part impact the rest of your application. This means that the supervisor supervising this process manager should not "hang".
  * The process manager should not be able to have an invalid state.
  * Put simply, the above 3 points all indicate that you should start your processes in the `handle_continue` callback. This is very important.
  * The responsibility of "rebooting" your crashed processes is no longer with the process manager, but with the supervisor supervising these processes.
  * Your workers no longer keep your history. More about this in the next section.
* Some great students mentioned that when the process crashes, the history shouldn't be lost with it. They were completely right! For this reason, we're refactoring the following:
  * Similar to our worker setup with supervisors, we're going to do the same for our history keepers.
  * Make a `Assignment.HistoryKeeperManager`. Similar to our process manager (which is kind of an ambigious name now, but let's forget about that), it'll start N `Assignment.HistoryKeeperWorker` workers under a supervisor that supports dynamic workers out of the box and name-register this as `Assignment.HistoryKeeperSupervisor`.
  * This `HistoryKeeperManager` will ask your process manager what coin pairs are supported.
  * Your `HistoryKeeperManager` should by no means hold an invalid state when starting your application. (Hint, `handle_continue`!)
  * Every`HistoryKeeperWorker` will keep the history of a specific coin pair.
  * The `CoindataRetriever` worker will ask the responsible `HistoryKeeperWorker` what it should still clone.
  * [BONUS] You can update the timeframe of a specific coin.
* We're going to make our Logger a little bit more fancy:
  * When printing a message, we can give a "level" towards this message. This level indicates whether it is a debug message, information message, warning, etc... Use the levels mentioned [here](https://hexdocs.pm/logger/Logger.html).

## Module names, constraints, method names & tests

Following module names will be used:

* `Assignment.*` (In order to avoid confusion between AssignmentOne, Two. Three, ...)
  * `Assignment.RateLimiter` name registered under its module name.
  * `Assignment.CoindataRetrieverSupervisor` name registered under its module name.
  * `Assignment.CoindataSupervisor` (Yes, there are 2 supervisors here!) not name registered.
  * `Assignment.CoindataRetriever` not name registered.
  * `Assignment.ProcessManager` name registered under its module name.
  * `Assignment.HistoryKeeperWorkerSupervisor` name registered under its module name.
  * `Assignment.HistoryKeeperSupervisor` (Yes, there are 2 supervisors here!) not name registered.
  * `Assignment.HistoryKeeperWorker` not name registered.
  * `Assignment.HistoryKeeperManager` name registered under its module name.
* Function names:
  * The function names written in the tests must be used as well.
  * `Assignment.HistoryKeeperWorker.get_history/1` is the method that'll return the history. No longer your CoindataRetriever!
  * `Assignment.Logger.log/2` now takes 2 arguments. The first is the level and the second is the message.
  * `Assignment.HistoryKeeperWorker.get_pair_info/1` returns the currency pair in string format.
  * `Assignment.HistoryKeeperWorker.get_history` retrieves the history of the passed PID. The expected format will be `{"BTC_BTS", [%{...}, %{...}, ...]}`
  * `Assignment.HistoryKeeperWorker.request_timeframe/1` requests the next timeframe that the worker should retrieve.
  * [BONUS] `Assignment.HistoryKeeperWorker.update_timeframe(pid, %{from: _, until: _})` updates the new timeframe for that specific coin that it should clone. _Example usage: Assignment.HistoryKeeperManager.get_pid_for("USDT_BTC") |> Assignment.HistoryKeeperWorker.update_timeframe(%{from: 2_years_ago_in_unix, until: now_in_unix})_
  * `Assignment.HistoryKeeperManager.get_pid_for/1` returns the pid of the process that is keeping the history for that currency pair.
  * `Assignment.HistoryKeeperManager.retrieve_history_processes/0` returns a list of tuples. The first element of the tuple is a string (the currency pair) whereas the second element is the PID of the associated process.



* **_indicative_** tests -> check the file `assignment_two_test.exs`.

## Additional constraints

* We are changing the time frame from one week to 33 days. Test this with the sample config code.

* In order to score 50% on this PE, you need to make sure that the functionality of the first assignment works completely. This includes adjusting your timeframe when there are 1000 records!
