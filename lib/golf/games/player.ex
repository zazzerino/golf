defmodule Golf.Games.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :username, :turn, :position, :score, :hand, :heldCard]}
  schema "players" do
    belongs_to :game, Golf.Games.Game, type: :string
    belongs_to :user, Golf.Accounts.User
    field :turn, :integer
    timestamps(type: :utc_datetime)

    field :username, :string, virtual: true
    field :position, :string, virtual: true
    field :score, :integer, virtual: true

    field :hand, {:array, :map}, virtual: true
    field :heldCard, :string, virtual: true
  end

  def changeset(player, attrs \\ %{}) do
    player
    |> cast(attrs, [:game_id, :user_id, :turn])
    |> validate_required([:game_id, :user_id, :turn])
  end
end
