defmodule AssignmentOneTest do
  use ExUnit.Case

  alias AssignmentOne.{Logger, ProcessManager, RateLimiter, CoindataRetriever}

  test "Necessary processes are alive" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(500)

    assert Process.whereis(Logger) != nil
    assert Process.whereis(ProcessManager) != nil
    assert Process.whereis(RateLimiter) != nil
  end

  # Tests for ProcessManager
  test "ProcessManager returns list of currency pairs" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(1000)

    procs = ProcessManager.retrieve_coin_processes()

    assert Enum.all?(procs, &is_tuple/1)
    assert Enum.all?(procs, fn {bin, pid} -> is_binary(bin) and is_pid(pid) end)
    assert length(procs) > 90
  end

  test "ProcessManager restarts dead processes" do
    # Test are run in random order every time so sometimes coin data isn't there yet etc
    :timer.sleep(1000)

    amount_of_processes = ProcessManager.retrieve_coin_processes() |> length()

    ProcessManager.retrieve_coin_processes()
    |> List.first()
    |> elem(1)
    |> Process.exit(:kill)

    assert ProcessManager.retrieve_coin_processes() |> length() == amount_of_processes

    assert ProcessManager.retrieve_coin_processes()
           |> Enum.all?(fn {_, pid} -> Process.alive?(pid) == true end) == true
  end

  # Tests for Logger
  test "Logger can print" do
    Logger.log("LOGGER TEST, If you see this put value to true")

    assert true
  end

  # Tests for RateLimiter
  test "RateLimiter its value can be changed" do
    Logger.log("RATE TEST, If you see the speed of the requests go up after ~5 seconds, put value to true")

    RateLimiter.change_rate_limit(1)
    :timer.sleep(5000)
    RateLimiter.change_rate_limit(5)
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
    :timer.sleep(1000)

    pid =
      AssignmentOne.ProcessManager.retrieve_coin_processes()
      |> Enum.filter(fn {coin, _pid} -> coin == "BTC_DGB" end)
      |> List.first()
      |> elem(1)

    length_old = CoindataRetriever.get_history(pid) |> elem(1) |> length
    :timer.sleep(21_000)
    length_new = CoindataRetriever.get_history(pid) |> elem(1) |> length
    assert length_new > length_old
  end
end
