defmodule Golf.Chat do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Chat.Message

  def insert_message(message) do
    message
    |> Message.changeset()
    |> Repo.insert()
  end

  def get_messages(topic) do
    from(m in Message,
      where: [topic: ^topic],
      order_by: [asc: m.id]
    )
    |> Repo.all()
    |> Repo.preload(:user)
  end
end
