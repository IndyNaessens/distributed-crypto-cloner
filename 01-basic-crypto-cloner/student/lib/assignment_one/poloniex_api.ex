defmodule AssignmentOne.PoloniexAPiCaller do
  @moduledoc """
  A limited implementation of the PoloniexAPiCaller.

  Info => https://docs.poloniex.com
  """

  @url "https://poloniex.com/public"

  ### API
  def return_ticker() do
    "#{@url}?command=returnTicker"
    |> HTTPoison.get()
    |> handle_response()
  end

  def return_trade_history(currency_name, start_date_unix, end_date_unix)
      when is_binary(currency_name) do
    AssignmentOne.Logger.log(
      "Requesting coin trade history: #{currency_name} -> start: #{start_date_unix} end: #{
        end_date_unix
      }"
    )

    AssignmentOne.Logger.log(
      "Request for coin #{currency_name} is executed at #{
        DateTime.utc_now() |> DateTime.to_unix()
      }"
    )

    "#{@url}?command=returnTradeHistory&currencyPair=#{currency_name}&start=#{start_date_unix}&end=#{
      end_date_unix
    }"
    |> HTTPoison.get()
    |> AssignmentOne.Logger.return_and_log("Request finished for coin: #{currency_name}")
    |> handle_response()
  end

  ### HELPERS
  defp handle_response({:ok, %{status_code: 200, body: body}}) do
    Poison.Parser.parse!(body, %{})
  end

  defp handle_response({_, %{status_code: status_code, body: _}}) do
    AssignmentOne.Logger.log("Failed while handling repsonse, status: #{status_code}")
    %{}
  end
end
