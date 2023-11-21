defmodule Golf.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, []}
  @foreign_key_type :binary_id

  schema "games" do
    belongs_to :host, Golf.Accounts.User
    has_one :opts, Golf.Games.Opts
    timestamps(type: :utc_datetime)
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:host_id])
    |> validate_required([:host_id])
  end
end
