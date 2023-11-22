defmodule Golf.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}

  schema "games" do
    belongs_to :host, Golf.Accounts.User
    has_one :opts, Golf.Games.Opts
    has_many :players, Golf.Games.Player
    has_many :rounds, Golf.Games.Round
    timestamps(type: :utc_datetime)
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:id, :host_id])
    |> validate_required([:id, :host_id])
  end
end
