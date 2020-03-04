defmodule TelegramBot.API do
  use GenServer

  # Interface

  def start_link(token) do
    GenServer.start_link(__MODULE__, %{token: token}, name: __MODULE__)
  end

  def get_updates do
    GenServer.call(__MODULE__, :get_updates)
  end

  def send_message(options) do
    GenServer.call(__MODULE__, {:send_message, options)})
  end

  # Callbacks

  @impl true
  def init(%{token: token}) do
    {:ok, connection} = TelegramBot.Connection.start_link
    {:ok, %{token: token, connection: connection, offset: nil}}
  end

  @impl true
  def handle_call(:get_updates, _from, state) do
    case TelegramBot.Connection.request(
      state.connection,
      "GET",
      "/bot#{state.token}/getUpdates?offset=#{state.offset}",
      [],
      ""
    ) do
      {:ok, response} ->
        messages = response
          |> Map.get(:data)
          |> Poison.decode!
          |> Map.get("result")

        # Take update_id from last message to use it in the next getUpdates request
        # We assume that message ordering is guaranteed,
        # otherwise the whole message processing is broken
        last_message = List.last(messages)
        state = case last_message do
          %{"update_id" => last_update_id} ->
              put_in(state.offset, last_update_id + 1)
          _ ->
            state
        end

        parsed_messages = messages
          |> Stream.map(fn msg -> msg["message"] end)
          |> Enum.map(&TelegramBot.Message.parse/1)

        IO.inspect(state)
        {:reply, {:ok, parsed_messages}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:send_message, options}, _from, state) do
    case TelegramBot.Connection.request(
      state.connection,
      "POST",
      "/bot#{state.token}/sendMessage",
      [{"Content-Type", "application/json"}],
      Poison.encode!(options)
    ) do
      {:ok, response} -> {:reply, {:ok, response}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end
end
