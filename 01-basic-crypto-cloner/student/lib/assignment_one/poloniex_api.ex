defmodule AssignmentOne.PoloniexAPiCaller do
  @url "https://poloniex.com/public"

  ### API
  def return_ticker() do
    "#{@url}?command=returnTicker"
    |> HTTPoison.get()
    |> handle_response(200)
  end

  def return_trade_history(currency_pair, start_date_unix, end_date_unix)
      when is_binary(currency_pair) do
    AssignmentOne.Logger.log(
      "Requesting coin trade history: #{currency_pair} -> start: #{start_date_unix} end: #{
        end_date_unix
      }"
    )

    "#{@url}?command=returnTradeHistory&currencyPair=#{currency_pair}&start=#{start_date_unix}&end=#{
      end_date_unix
    }"
    |> HTTPoison.get()
    |> handle_response(200)
  end

  ### HELPERS
  defp handle_response({:ok, %{status_code: status, body: body}}, status)
       when is_integer(status) do
    Poison.Parser.parse!(body, %{})
  end

  defp handle_response({_, %{status_code: _, body: _}}, _) do
    %{}
  end
end
