defmodule Golf.Games.Round do
  use Ecto.Schema
  import Ecto.Changeset

  @states [:flip_2, :take, :hold, :flip, :round_over]

  schema "rounds" do
    belongs_to :game, Golf.Games.Game, type: :string

    field :state, Ecto.Enum, values: @states
    field :flipped?, :boolean, default: false
    field :turn, :integer
    field :deck, {:array, :string}, default: []
    field :table_cards, {:array, :string}, default: []
    field :hands, {:array, {:array, :map}}, default: []
    field :held_card, :map

    has_many :events, Golf.Games.Event
    timestamps(type: :utc_datetime)
  end

  def changeset(round, attrs \\ %{}) do
    round
    |> cast(attrs, [:game_id, :state, :flipped?, :turn, :deck, :table_cards, :hands, :held_card])
    |> validate_required([:game_id, :state, :flipped?, :turn, :deck, :table_cards, :hands])
  end
end
