defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  alias Golf.{Games, GamesDb}
  alias Golf.Games.{Player, Event}
  alias Golf.Games.ClientData, as: Data

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2>
        <span class="font-bold">Game</span> <%= @id %>
      </h2>

      <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>

      <.button :if={@can_start?} phx-click="start-game">
        Start Game
      </.button>
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_game, id})
    end

    {:ok,
     assign(socket,
       page_title: "Game",
       id: id,
       game: nil,
       can_start?: nil
     )}
  end

  @impl true
  def handle_info({:load_game, id}, socket) do
    case GamesDb.get_game(id) do
      nil ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      game ->
        user = socket.assigns.current_user
        data = Data.from(game, user)
        host? = user.id == game.host_id

        :ok = Golf.subscribe("game:#{id}")

        {:noreply,
         assign(socket,
           game: game,
           can_start?: host? and data.state == :no_round
         )
         |> push_event("game-loaded", %{"game" => data})}
    end
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    data = Data.from(game, socket.assigns.current_user)

    {:noreply,
     assign(socket, game: game, can_start?: false)
     |> push_event("game-started", %{"game" => data})}
  end

  @impl true
  def handle_info({:game_event, game, event}, socket) do
    data = Data.from(game, socket.assigns.current_user)

    {:noreply,
     assign(socket, game: game)
     |> push_event("game-event", %{"game" => data, "event" => event})}
  end

  @impl true
  def handle_event("start-game", _params, socket) do
    {:ok, game} = GamesDb.start_round(socket.assigns.game)
    :ok = Golf.broadcast("game:#{game.id}", {:game_started, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event("hand-click", %{"playerId" => player_id, "handIndex" => hand_index}, socket) do
    handle_game_event(socket.assigns.game, "hand", player_id, hand_index)
    {:noreply, socket}
  end

  @impl true
  def handle_event("deck-click", %{"playerId" => player_id}, socket) do
    handle_game_event(socket.assigns.game, "deck", player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("table-click", %{"playerId" => player_id}, socket) do
    handle_game_event(socket.assigns.game, "table", player_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("held-click", %{"playerId" => player_id}, socket) do
    handle_game_event(socket.assigns.game, "held", player_id)
    {:noreply, socket}
  end

  defp handle_game_event(game, place, player_id, hand_index \\ nil) do
    %Player{} = player = Enum.find(game.players, &(&1.id == player_id))

    state = Games.current_state(game)
    action = action_at(state, place)
    event = Event.new(game, player, action, hand_index)
    {:ok, game} = GamesDb.handle_event(game, event) |> dbg()

    broadcast_game_event(game, event)
  end

  defp action_at(state, "hand") when state in [:flip_2, :flip], do: :flip
  defp action_at(:take, "table"), do: :take_table
  defp action_at(:take, "deck"), do: :take_deck
  defp action_at(:hold, "held"), do: :discard
  defp action_at(:hold, "hand"), do: :swap

  defp broadcast_game_event(game, event) do
    Golf.broadcast("game:#{game.id}", {:game_event, game, event})
  end

  # :ok = Golf.broadcast(topic(game.id), {:game_event, game, event})

  # if Games.current_state(game) == :round_over do
  #   :ok = Golf.broadcast(topic(game.id), {:round_over, game})
  # end

  # case Games.current_state(game) do
  #   :round_over ->
  #     :ok = Golf.broadcast(topic(game.id), {:round_over, game})

  #   :game_over ->
  #     :ok = Golf.broadcast(topic(game.id), {:game_over, game})

  #   _ ->
  #     nil
  # end
end
