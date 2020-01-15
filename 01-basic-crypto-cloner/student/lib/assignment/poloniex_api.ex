defmodule Assignment.PoloniexAPiCaller do
  @moduledoc """
  This is the PoloniexAPiCaller module

  It is a very limited implementation of the PoloniexAPiCaller.

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
    "#{@url}?command=returnTradeHistory&currencyPair=#{currency_name}&start=#{start_date_unix}&end=#{
      end_date_unix
    }"
    |> HTTPoison.get()
    |> handle_response()
  end

  ### HELPERS
  defp handle_response({:ok, %{status_code: 200, body: body}}) do
    Poison.Parser.parse!(body, %{})
  end

  defp handle_response({:error, %{id: _id, reason: _msg}}) do
    :poloniex_api_error
  end
end
