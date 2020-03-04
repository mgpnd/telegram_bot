defmodule TelegramBot.Connection do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  # Interface

  def request(pid, method, url, headers \\ [], body \\ "") do
    GenServer.call(pid, {:request, method, url, headers, body})
  end

  # Callbacks

  @impl true
  def init(_) do
    {:ok, conn} = Mint.HTTP.connect(:https, "api.telegram.org", 443)
    {:ok, %{conn: conn, requests: %{}}}
  end

  @impl true
  def handle_call({:request, method, url, headers, body}, from, state) do
    case Mint.HTTP.request(state.conn, method, url, headers, body) do
      {:ok, conn, request_ref} ->
        state = put_in(state.conn, conn)
        state = put_in(state.requests[request_ref], %{from: from, response: %{}})
        {:noreply, state}

      {:error, conn, reason} ->
        state = put_in(state.conn, conn)
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(message, state) do
    case Mint.HTTP.stream(state.conn, message) do
      :unknown ->
        {:noreply, state}

      {:ok, conn, responses} ->
        state = put_in(state.conn, conn)
        state = Enum.reduce(responses, state, &process_response/2)
        {:noreply, state}

      {:error, conn, _error, _responses} ->
        state = put_in(state.conn, conn)
        {:noreply, state}
    end
  end

  defp process_response({:status, request_ref, status}, state) do
    put_in(state.requests[request_ref].response[:status], status)
  end

  defp process_response({:headers, request_ref, headers}, state) do
    put_in(state.requests[request_ref].response[:headers], headers)
  end

  defp process_response({:data, request_ref, new_data}, state) do
    update_in(state.requests[request_ref].response[:data], fn data -> (data || "") <> new_data end)
  end

  defp process_response({:done, request_ref}, state) do
    {%{response: response, from: from}, state} = pop_in(state.requests[request_ref])
    GenServer.reply(from, {:ok, response})
    state
  end
end
