defmodule Golf.GamesTest do
  use Golf.DataCase

  alias Golf.{Games, GamesDb}
  alias Golf.Games.{Opts, Event}

  test "two player game" do
    user1 = Golf.AccountsFixtures.user_fixture()
    user2 = Golf.AccountsFixtures.user_fixture()

    id = Golf.gen_id()
    users = [user1, user2]
    opts = %Opts{num_rounds: 2}

    {:ok, game} = GamesDb.create_game(id, users, opts)

    p1 = Enum.at(game.players, 0)
    p2 = Enum.at(game.players, 1)

    assert Games.current_state(game) == :no_round
    refute Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    {:ok, game} = GamesDb.start_round(game)

    assert Games.current_state(game) == :flip_2
    assert Games.current_round(game).turn == 0
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 0)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip_2
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :flip, 5)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip_2
    assert Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :flip, 4)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip_2
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 1)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 1
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :discard)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 2)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_table)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_round(game).turn == 2
    assert Games.current_state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :swap, 3)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 3
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :discard)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 3)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 4
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :swap, 2)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.current_round(game).turn == 5
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_table)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :discard)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :flip
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :flip, 4)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    event = Event.new(game, p2, :take_deck)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    refute Games.current_round(game).flipped?

    event = Event.new(game, p2, :swap, 2)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :take_table)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :hold
    assert Games.can_act?(game, p1)
    refute Games.can_act?(game, p2)

    event = Event.new(game, p1, :swap, 5)
    {:ok, game} = GamesDb.handle_event(game, event)

    assert Games.current_state(game) == :take
    refute Games.can_act?(game, p1)
    assert Games.can_act?(game, p2)

    assert Games.current_round(game).flipped?
    assert Games.current_round(game).turn == 8
    dbg(game)
  end
end

# describe "games" do
#   alias Golf.Games.Game

#   import Golf.GamesFixtures

#   @invalid_attrs %{}

#   test "list_games/0 returns all games" do
#     game = game_fixture()
#     assert Games.list_games() == [game]
#   end

#   test "get_game!/1 returns the game with given id" do
#     game = game_fixture()
#     assert Games.get_game!(game.id) == game
#   end

#   test "create_game/1 with valid data creates a game" do
#     valid_attrs = %{}

#     assert {:ok, %Game{} = game} = Games.create_game(valid_attrs)
#   end

#   test "create_game/1 with invalid data returns error changeset" do
#     assert {:error, %Ecto.Changeset{}} = Games.create_game(@invalid_attrs)
#   end

#   test "update_game/2 with valid data updates the game" do
#     game = game_fixture()
#     update_attrs = %{}

#     assert {:ok, %Game{} = game} = Games.update_game(game, update_attrs)
#   end

#   test "update_game/2 with invalid data returns error changeset" do
#     game = game_fixture()
#     assert {:error, %Ecto.Changeset{}} = Games.update_game(game, @invalid_attrs)
#     assert game == Games.get_game!(game.id)
#   end

#   test "delete_game/1 deletes the game" do
#     game = game_fixture()
#     assert {:ok, %Game{}} = Games.delete_game(game)
#     assert_raise Ecto.NoResultsError, fn -> Games.get_game!(game.id) end
#   end

#   test "change_game/1 returns a game changeset" do
#     game = game_fixture()
#     assert %Ecto.Changeset{} = Games.change_game(game)
#   end
# end
