defmodule Golf.Chat do
  import Ecto.Query

  alias Golf.Repo
  alias Golf.Chat.Message
  alias Golf.Accounts.User

  def insert_message(message) do
    message
    |> Message.changeset()
    |> Repo.insert()
  end

  def get_messages(topic) do
    from(m in Message,
      where: [topic: ^topic],
      order_by: [asc: m.id],
      join: u in User,
      on: u.id == m.user_id,
      select: m
    )
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.map(&put_username/1)
  end

  defp put_username(msg) do
    name = String.split(msg.user.email, "@") |> List.first()
    Map.put(msg, :username, name)
  end
end
