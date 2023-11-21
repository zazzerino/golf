defmodule Golf.Games.Opts do
  use Ecto.Schema
  import Ecto.Changeset

  schema "opts" do
    belongs_to :game, Golf.Games.Game, type: :string
    field :num_rounds, :integer, default: 1
  end

  def changeset(opts, attrs \\ %{}) do
    opts
    |> cast(attrs, [:num_rounds])
    |> validate_required([:num_rounds])
  end

  def default(), do: %__MODULE__{num_rounds: 1}
end
