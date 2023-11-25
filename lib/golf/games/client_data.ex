defmodule Golf.Games.ClientData do
  @derive Jason.Encoder
  defstruct [
    :id,
    :turn,
    :state,
    :isFlipped,
    :deck,
    :tableCards,
    :players,
    :playerId,
    :playableCards
  ]

  def from(game, user) do
    index = Enum.find_index(game.players, &(&1.user_id == user.id))
    player = if index, do: Enum.at(game.players, index)

    num_players = length(game.players)
    positions = player_positions(num_players)

    round = Golf.Games.current_round(game)
    turn = if round, do: round.turn
    hands = if round, do: maybe_rotate(round.hands, index), else: []
    held_card = if round, do: round.held_card

    playable_cards =
      if player && round do
        Golf.Games.playable_cards(round, player, num_players)
      else
        []
      end

    players =
      game.players
      |> maybe_rotate(index)
      |> put_hands(hands)
      |> Enum.map(&put_can_act?(&1, game))
      |> Enum.map(&put_username/1)
      |> Enum.map(&put_held_card(&1, held_card))
      |> Enum.zip_with(positions, &put_position/2)

    %__MODULE__{
      id: game.id,
      turn: turn,
      state: Golf.Games.current_state(game),
      isFlipped: round && round.flipped?,
      deck: (round && round.deck) || [],
      tableCards: (round && round.table_cards) || [],
      players: players,
      playerId: player && player.id,
      playableCards: playable_cards
    }
  end

  defp player_positions(num_players) do
    case num_players do
      1 -> ~w(bottom)
      2 -> ~w(bottom top)
      3 -> ~w(bottom left right)
      4 -> ~w(bottom left top right)
    end
  end

  defp put_can_act?(player, game) do
    %{player | canAct: Golf.Games.can_act?(game, player)}
  end

  defp put_username(player) do
    %{player | username: player.user.name}
  end

  defp put_position(player, pos) do
    Map.put(player, :position, pos)
  end

  defp put_hands(players, []) do
    Enum.map(players, fn p -> %{p | hand: [], score: 0} end)
  end

  defp put_hands(players, hands) do
    Enum.zip_with(players, hands, fn p, hand ->
      %{p | hand: hand, score: Golf.Games.score(hand)}
    end)
  end

  defp put_held_card(p, %{"player_id" => card_pid} = card) when p.id == card_pid do
    %{p | heldCard: card["name"]}
  end

  defp put_held_card(player, _), do: player

  def maybe_rotate(list, n) when n in [0, nil], do: list
  def maybe_rotate(list, n), do: Golf.rotate(list, n)
end
