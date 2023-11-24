defmodule Golf.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    belongs_to :user, Golf.Accounts.User
    field :topic, :string
    field :content, :string

    field :username, :string, virtual: true

    timestamps(type: :utc_datetime)
  end

  def changeset(message, attrs \\ %{}) do
    message
    |> cast(attrs, [:user_id, :username, :topic])
    |> validate_required([:user_id, :topic])
  end

  def new(topic, user, content) do
    %__MODULE__{
      topic: topic,
      content: content,
      user_id: user.id,
      username: String.split(user.email, "@") |> List.first()
    }
  end
end
