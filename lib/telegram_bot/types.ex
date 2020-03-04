defmodule TelegramBot.User do
  @enforce_keys [:id, :is_bot, :first_name]
  defstruct [:id, :is_bot, :first_name, :last_name, :username]

  def parse(input) do
    %__MODULE__{
      id: input["id"],
      is_bot: input["is_bot"],
      first_name: input["first_name"],
      last_name: input["last_name"],
      username: input["username"],
    }
  end
end

defmodule TelegramBot.Chat do
  @enforce_keys [:id, :type]
  defstruct [:id, :type, :title]

  def parse(input) do
    %__MODULE__{
      id: input["id"],
      type: input["type"],
      title: input["title"],
    }
  end
end

defmodule TelegramBot.Message do
  @enforce_keys [:message_id, :date, :chat]
  defstruct [:message_id, :date, :chat, :from, :text]

  def parse(input) do
    {:ok, date} = DateTime.from_unix(input["date"])

    %__MODULE__{
      message_id: input["message_id"],
      text: input["text"],
      date: date,
      chat: TelegramBot.Chat.parse(input["chat"]),
      from: input["from"] && TelegramBot.User.parse(input["from"]),
    }
  end
end
