defmodule AssignmentOneTest do
  use ExUnit.Case

  alias AssignmentOne.{Logger, ProcessManager, RateLimiter, CoindataRetriever}

  test "Necessary processes are alive" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(2000)

    assert Process.whereis(Logger) != nil
    assert Process.whereis(ProcessManager) != nil
    assert Process.whereis(RateLimiter) != nil
  end

  # Tests for ProcessManager
  test "ProcessManager returns list of currency pairs" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(2000)

    procs = ProcessManager.retrieve_coin_processes()

    assert Enum.all?(procs, &is_tuple/1)
    assert Enum.all?(procs, fn {bin, pid} -> is_binary(bin) and is_pid(pid) end)
    assert length(procs) > 90
  end

  test "ProcessManager restarts dead processes" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(2000)

    amount_of_processes = ProcessManager.retrieve_coin_processes() |> length()

    ProcessManager.retrieve_coin_processes()
    |> List.first()
    |> elem(1)
    |> Process.exit(:kill)

    assert ProcessManager.retrieve_coin_processes() |> length() == amount_of_processes

    :timer.sleep(2000)

    assert ProcessManager.retrieve_coin_processes()
           |> Enum.all?(fn {_, pid} -> Process.alive?(pid) == true end) == true
  end

  # Tests for Logger
  test "Logger can print" do
    Logger.log("\n\n\nLOGGER TEST, If you see this put value to true\n\n\n")

    assert true
  end

  # Tests for RateLimiter
  test "\n\n\nRateLimiter its value can be changed" do
    Logger.log(
      "\n\n\nRATE TEST, If you see the speed of the requests go up after ~5 seconds, put value to true\n\n\n"
    )

    RateLimiter.change_rate_limit(1)
    :timer.sleep(5000)
    RateLimiter.change_rate_limit(5)
    Logger.log("\n\n\n")
    :timer.sleep(3000)
    assert true
  end

  test "After calling change_rate_limit/1, the limit is changed to the value provided as argument" do
    old_rate_limit = RateLimiter.current_rate_limit()
    RateLimiter.change_rate_limit(old_rate_limit + 1)

    assert old_rate_limit + 1 == RateLimiter.current_rate_limit()
  end

  # Tests for CoinDataRetriever
  test "CoinDataRetriever actually gets new values" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(2000)

    Logger.log("\n\n\nStarting CoinDataRetriever test, this wil take ~2 mins. Why?
    \nThis time is so long because when we split the time frame and ask the ratelimiter for permission it adds us at the end of the queue.
    \nWhen a request comes back with 1000 trades we don't add any of it to the history we just split it and do 2 requests with a smaller timeframe.
    \n\n\n")

    pid =
      AssignmentOne.ProcessManager.retrieve_coin_processes()
      |> Enum.filter(fn {coin, _pid} -> coin == "BTC_DGB" end)
      |> List.first()
      |> elem(1)

    length_old = CoindataRetriever.get_history(pid) |> elem(1) |> length

    # this time is so long because when we split the time frame and ask the ratelimiter for permission it adds us at the end of the queue
    # queue is first in first out but the ratelimiter only knows pids so when a coin does a request and gets back 1000 results
    # it will ask the ratelimiter for 2 new requests but has bad luck and is at the end of the queue now
    :timer.sleep(120_000)
    length_new = CoindataRetriever.get_history(pid) |> elem(1) |> length
    assert length_new > length_old
  end
end
