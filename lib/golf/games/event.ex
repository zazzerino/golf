defmodule Golf.Games.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @actions [:take_from_deck, :take_from_table, :swap, :discard, :flip]

  @derive {Jason.Encoder, only: [:round_id, :player_id, :action, :data]}
  schema "events" do
    belongs_to :round, Golf.Games.Round
    belongs_to :player, Golf.Games.Player

    field :action, Ecto.Enum, values: @actions
    field :data, :map

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [:round_id, :player_id, :action, :data])
    |> validate_required([:round_id, :player_id, :action])
  end

  # def new(%Game{rounds: [round | _]}, player, action, hand_index) do
  #   new(round, player, action, hand_index)
  # end

  # def new(%Round{} = round, player, action, hand_index) do
  #   %__MODULE__{
  #     round_id: round.id,
  #     player_id: player.id,
  #     player: player,
  #     action: action,
  #     hand_index: hand_index
  #   }
  # end
end