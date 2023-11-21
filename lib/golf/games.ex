defmodule Golf.Games do
  alias Golf.Games.{Game, Player, Opts, Round, Event}

  @card_names for rank <- ~w(A 2 3 4 5 6 7 8 9 T J Q K),
                  suit <- ~w(C D H S),
                  do: rank <> suit

  @num_decks 2
  @hand_size 6

  def new_game(id, [host | _] = users, opts \\ Opts.default()) do
    players =
      Enum.with_index(users)
      |> Enum.map(fn {user, i} -> %Player{user_id: user.id, turn: i} end)

    %Game{
      id: id,
      host_id: host.id,
      opts: opts,
      players: players,
      rounds: []
    }
  end

  def new_round(game) do
    deck = Enum.shuffle(new_deck(@num_decks))
    num_hand_cards = @hand_size * length(game.players)

    {:ok, hand_cards, deck} = deal_from_deck(deck, num_hand_cards)
    {:ok, table_card, deck} = deal_from_deck(deck)

    hands =
      hand_cards
      |> Enum.map(&%{"name" => &1, "face_up?" => false})
      |> Enum.chunk_every(@hand_size)

    %Round{
      game_id: game.id,
      state: :flip_2,
      turn: 0,
      deck: deck,
      hands: hands,
      table_cards: [table_card],
      events: []
    }
  end

  def current_round(%Game{rounds: [round | _]}), do: round
  def current_round(_), do: nil

  def current_state(%Game{rounds: [round | _]} = game)
      when round.state == :round_over and length(game.rounds) >= game.opts.num_rounds do
    :game_over
  end

  def current_state(%Game{rounds: []}), do: :no_round
  def current_state(%Game{rounds: [round | _]}), do: round.state

  def can_act?(%Game{rounds: []}, _), do: false

  def can_act?(%Game{rounds: [round | _]} = game, player) do
    can_act_round?(round, player, length(game.players))
  end

  def can_act_round?(%Round{state: :round_over}, _, _), do: false

  def can_act_round?(%Round{state: :flip_2} = round, player, _) do
    hand = Enum.at(round.hands, player.turn)
    num_cards_face_up(hand) < 2
  end

  def can_act_round?(round, player, num_players) do
    rem(round.turn, num_players) == player.turn
  end

  def round_changes(%Round{state: :flip_2} = round, %Event{action: :flip} = event) do
    hands =
      List.update_at(
        round.hands,
        event.player.turn,
        &flip_card_at(&1, event.data.hand_index)
      )

    state =
      if Enum.all?(hands, &min_two_face_up?/1) do
        :take
      else
        :flip_2
      end

    %{state: state, hands: hands}
  end

  def round_changes(%Round{state: :flip} = round, %Event{action: :flip} = event) do
    hand =
      round.hands
      |> Enum.at(event.player.turn)
      |> flip_card_at(event.data.hand_index)

    hands = List.replace_at(round.hands, event.player.turn, hand)

    {state, turn, flipped?} =
      cond do
        Enum.all?(hands, &all_face_up?/1) ->
          {:round_over, round.turn, true}

        all_face_up?(hand) ->
          {:take, round.turn + 1, true}

        true ->
          {:take, round.turn + 1, round.flipped?}
      end

    %{state: state, turn: turn, hands: hands, flipped?: flipped?}
  end

  def round_changes(%Round{state: :take} = round, %Event{action: :take_from_deck} = event) do
    {:ok, card, deck} = deal_from_deck(round.deck)

    %{
      state: :hold,
      deck: deck,
      held_card: %{"player_id" => event.player.id, "name" => card}
    }
  end

  def round_changes(%Round{state: :take} = round, %Event{action: :take_from_table} = event) do
    [card | table_cards] = round.table_cards

    %{
      state: :hold,
      table_cards: table_cards,
      held_card: %{"player_id" => event.player.id, "name" => card}
    }
  end

  def round_changes(
        %Round{state: :hold, flipped?: false} = round,
        %Event{action: :discard} = event
      ) do
    hand = Enum.at(round.hands, event.player.turn)

    {state, turn, flipped?} =
      cond do
        all_face_up?(hand) ->
          {:take, round.turn + 1, true}

        one_face_down?(hand) ->
          {:take, round.turn + 1, false}

        true ->
          {:flip, round.turn, false}
      end

    %{
      state: state,
      turn: turn,
      held_card: nil,
      table_cards: [round.held_card["name"] | round.table_cards],
      flipped?: flipped?
    }
  end

  def round_changes(
        %Round{state: :hold, flipped?: true} = round,
        %Event{action: :discard} = event
      ) do
    hands = List.update_at(round.hands, event.player.turn, &flip_all/1)

    {state, turn} =
      if Enum.all?(hands, &all_face_up?/1) do
        {:round_over, round.turn}
      else
        {:take, round.turn + 1}
      end

    %{
      state: state,
      turn: turn,
      hands: hands,
      held_card: nil,
      table_cards: [round.held_card["name"] | round.table_cards]
    }
  end

  def round_changes(
        %Round{state: :hold} = round,
        %Event{action: :swap} = event
      ) do
    {hand, card} =
      round.hands
      |> Enum.at(event.player.turn)
      |> maybe_flip_all(round.flipped?)
      |> swap_card(event.data.hand_index, round.held_card["name"])

    hands = List.replace_at(round.hands, event.player.turn, hand)

    {state, turn, flipped?} =
      cond do
        Enum.all?(hands, &all_face_up?/1) ->
          {:round_over, round.turn, true}

        all_face_up?(hand) ->
          {:take, round.turn + 1, true}

        true ->
          {:take, round.turn + 1, round.flipped?}
      end

    %{
      state: state,
      turn: turn,
      held_card: nil,
      hands: hands,
      table_cards: [card | round.table_cards],
      flipped?: flipped?
    }
  end

  def playable_cards(%Round{state: :flip_2} = round, player, _) do
    hand = Enum.at(round.hands, player.turn)

    if num_cards_face_up(hand) < 2 do
      face_down_cards(hand)
    else
      []
    end
  end

  def playable_cards(round, player, num_players) do
    if can_act_round?(round, player, num_players) do
      hand = Enum.at(round.hands, player.turn)
      places(round.state, round.flipped?, hand)
    else
      []
    end
  end

  defp places(_state, _flipped?, _hand)
  defp places(:take, true, hand), do: [:deck, :table] ++ face_down_cards(hand)
  defp places(:take, false, _), do: [:deck, :table]
  defp places(:flip, _, hand), do: face_down_cards(hand)
  defp places(:hold, _, _), do: [:held, :hand_0, :hand_1, :hand_2, :hand_3, :hand_4, :hand_5]

  def score(hand) do
    hand
    |> Enum.map(&rank_if_face_up/1)
    |> score_ranks(0)
  end

  defp rank_value(rank) when is_integer(rank) do
    case rank do
      ?K -> 0
      ?A -> 1
      ?2 -> 2
      ?3 -> 3
      ?4 -> 4
      ?5 -> 5
      ?6 -> 6
      ?7 -> 7
      ?8 -> 8
      ?9 -> 9
      r when r in [?T, ?J, ?Q] -> 10
    end
  end

  defp rank_if_face_up(%{"face_up?" => true, "name" => <<rank, _>>}), do: rank
  defp rank_if_face_up(_), do: nil

  # Each hand consists of two rows of three cards.
  # Face down cards are represented by nil and ignored.
  # If the cards are face up and in a matching column, they are worth 0 points and discarded.

  # Special cases:
  #   6 of a kind -> -40 pts
  #   4 of a kind (outer cols) -> -20 pts
  #   4 of a kind (adjacent cols) -> -10 pts

  # The rank value of each remaining face up card is totaled together.
  defp score_ranks(ranks, total) do
    case ranks do
      # all match, -40 points
      [a, a, a,
       a, a, a] when is_integer(a) ->
        -40

      # outer cols match, -20 points
      [a, b, a,
       a, c, a] when is_integer(a) ->
        score_ranks([b, c], total - 20)

      # left 2 cols match, -10 points
      [a, a, b,
       a, a, c] when is_integer(a) ->
        score_ranks([b, c], total - 10)

      # right 2 cols match, -10 points
      [a, b, b,
       c, b, b] when is_integer(b) ->
        score_ranks([a, c], total - 10)

      # left col match
      [a, b, c,
       a, d, e] when is_integer(a) ->
        score_ranks([b, c, d, e], total)

      # middle col match
      [a, b, c,
       d, b, e] when is_integer(b) ->
        score_ranks([a, c, d, e], total)

      # right col match
      [a, b, c,
       d, e, c] when is_integer(c) ->
        score_ranks([a, b, d, e], total)

      # left col match, pass 2
      [a, b,
       a, c] when is_integer(a) ->
        score_ranks([b, c], total)

      # right col match, pass 2
      [a, b,
       c, b] when is_integer(b) ->
        score_ranks([a, c], total)

      # match, pass 3
      [a,
       a] when is_integer(a) ->
        total

      # no matches, add the rank val of each face up card to the total
      _ ->
        ranks
        |> Enum.reject(&is_nil/1)
        |> Enum.reduce(total, fn rank, acc -> rank_value(rank) + acc end)
    end
  end

  defp flip_card(card) do
    %{card | "face_up?" => true}
  end

  defp flip_card_at(hand, index) do
    List.update_at(hand, index, &flip_card/1)
  end

  defp flip_all(hand) do
    Enum.map(hand, &flip_card/1)
  end

  defp maybe_flip_all(hand, true), do: flip_all(hand)
  defp maybe_flip_all(hand, _), do: hand

  defp swap_card(hand, index, new_card) do
    old_card = Enum.at(hand, index)["name"]
    hand = List.replace_at(hand, index, %{"name" => new_card, "face_up?" => true})
    {hand, old_card}
  end

  defp num_cards_face_up(hand) do
    Enum.count(hand, & &1["face_up?"])
  end

  defp all_face_up?(hand) do
    num_cards_face_up(hand) == @hand_size
  end

  defp one_face_down?(hand) do
    num_cards_face_up(hand) == @hand_size - 1
  end

  defp min_two_face_up?(hand) do
    num_cards_face_up(hand) >= 2
  end

  defp face_down_cards(hand) do
    hand
    |> Enum.with_index()
    |> Enum.reject(fn {card, _} -> card["face_up?"] end)
    |> Enum.map(fn {_, index} -> String.to_existing_atom("hand_#{index}") end)
  end

  defp new_deck(1), do: @card_names

  defp new_deck(n) when n > 1 do
    @card_names ++ new_deck(n - 1)
  end

  defp deal_from_deck([], _) do
    {:error, :empty_deck}
  end

  defp deal_from_deck(deck, n) when length(deck) < n do
    {:error, :not_enough_cards}
  end

  defp deal_from_deck(deck, n) do
    {cards, deck} = Enum.split(deck, n)
    {:ok, cards, deck}
  end

  defp deal_from_deck(deck) do
    with {:ok, [card], deck} <- deal_from_deck(deck, 1) do
      {:ok, card, deck}
    end
  end
end
