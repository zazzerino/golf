defmodule Golf.Games.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    belongs_to :game, Golf.Games.Game
    belongs_to :user, Golf.Accounts.User
    field :turn, :integer
    timestamps(type: :utc_datetime)
  end

  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:game_id, :user_id, :turn])
    |> validate_required([:game_id, :user_id, :turn])
  end
end
