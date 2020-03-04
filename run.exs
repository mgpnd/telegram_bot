token = "895733178:AAEroWNPRVw3QkpHl7ZxbaKUa_w5__CWipQ"
chat_id = "84396021"

TelegramBot.API.start_link(token)

{:ok, updates} = TelegramBot.API.get_updates

updates
  |> IO.inspect

# {:ok, response} = TelegramBot.API.send_message(chat_id, "123")

# response
#   |> IO.inspect
