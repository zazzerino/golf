defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.Components, only: [game_header: 1, chat: 1, player_scores: 1]

  alias Golf.{Games, GamesDb, Chat}
  alias Golf.Games.{Player, Event}
  alias Golf.Games.ClientData, as: Data

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <.game_header id={@id} />

      <div :if={@game_over?} class="font-bold">
        Game Over
      </div>

      <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>

      <.button :if={@can_start_game?} phx-click="start-game">
        Start Game
      </.button>

      <.button :if={@can_start_round?} phx-click="start-round">
        Start Round
      </.button>

      <div :if={@game}>
        <.player_scores players={@players} />
      </div>

      <.chat :if={@game} messages={@streams.chat_messages} submit="submit-chat" />
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_game, id})
      send(self(), {:load_chat_messages, id})
    end

    {:ok,
     assign(socket,
       page_title: "Game",
       id: id,
       game: nil,
       players: [],
       can_start_game?: nil,
       can_start_round?: nil,
       game_over?: nil
     )
     |> stream(:chat_messages, [])}
  end

  @impl true
  def handle_info({:load_game, id}, socket) do
    case GamesDb.get_game(id) do
      nil ->
        {:noreply,
         socket
         |> push_navigate(to: ~p"/")
         |> put_flash(:error, "Game #{id} not found.")}

      game ->
        user = socket.assigns.current_user
        host? = user.id == game.host_id
        data = Data.from(game, user)

        :ok = Golf.subscribe("game:#{id}")

        {:noreply,
         assign(socket,
           game: game,
           players: data.players,
           can_start_game?: host? and data.state == :no_round,
           can_start_round?: host? and data.state == :round_over,
           game_over?: data.state == :game_over
         )
         |> push_event("game-loaded", %{"game" => data})}
    end
  end

  @impl true
  def handle_info({:load_chat_messages, id}, socket) do
    messages = Golf.Chat.get_messages(id)
    :ok = Golf.subscribe("chat:#{id}")
    {:noreply, stream(socket, :chat_messages, messages, at: 0)}
  end

  @impl true
  def handle_info({:new_chat_message, message}, socket) do
    {:noreply, stream_insert(socket, :chat_messages, message, at: 0)}
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    data = Data.from(game, socket.assigns.current_user)

    {:noreply,
     assign(socket, game: game, can_start_game?: false)
     |> push_event("game-started", %{"game" => data})}
  end

  @impl true
  def handle_info({:round_started, game}, socket) do
    data = Data.from(game, socket.assigns.current_user)

    {:noreply,
     assign(socket, game: game, can_start_round?: false)
     |> push_event("round-started", %{"game" => data})}
  end

  @impl true
  def handle_info({:game_event, game, event}, socket) do
    data = Data.from(game, socket.assigns.current_user)

    {:noreply,
     assign(socket, game: game, players: data.players)
     |> push_event("game-event", %{"game" => data, "event" => event})}
  end

  @impl true
  def handle_info({:round_over, game}, socket) do
    can_start_round? = socket.assigns.current_user.id == game.host_id

    {:noreply,
     assign(socket, can_start_round?: can_start_round?)
     |> push_event("round-over", %{})}
  end

  @impl true
  def handle_info({:game_over, _game}, socket) do
    {:noreply, assign(socket, game_over?: true)}
  end

  @impl true
  def handle_event("start-game", _params, socket) do
    {:ok, game} = GamesDb.start_round(socket.assigns.game)
    :ok = Golf.broadcast("game:#{game.id}", {:game_started, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event("start-round", _params, socket) do
    {:ok, game} = GamesDb.start_round(socket.assigns.game)
    :ok = Golf.broadcast("game:#{game.id}", {:round_started, game})
    {:noreply, socket}
  end

  @impl true
  def handle_event("card-click", params, socket) do
    game = socket.assigns.game
    player = %Player{} = Enum.find(game.players, &(&1.id == params["playerId"]))

    state = Games.current_state(game)
    action = action_at(state, params["place"])
    event = Event.new(game, player, action, params["handIndex"])
    {:ok, game} = GamesDb.handle_event(game, event)

    :ok = broadcast_game_event(game, event)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-chat", %{"content" => content}, socket) do
    id = socket.assigns.id
    user = socket.assigns.current_user

    {:ok, message} =
      Chat.Message.new(id, user, content)
      |> Chat.insert_message()

    :ok = Golf.broadcast("chat:#{id}", {:new_chat_message, message})
    {:noreply, push_event(socket, "clear-chat-input", %{})}
  end

  defp action_at(state, "hand") when state in [:flip_2, :flip], do: :flip
  defp action_at(:take, "table"), do: :take_table
  defp action_at(:take, "deck"), do: :take_deck
  defp action_at(:hold, "held"), do: :discard
  defp action_at(:hold, "hand"), do: :swap

  defp broadcast_game_event(game, event) do
    topic = "game:#{game.id}"
    state = Games.current_state(game)

    :ok = Golf.broadcast(topic, {:game_event, game, event})

    case state do
      :game_over ->
        :ok = Golf.broadcast(topic, {:game_over, game})

      :round_over ->
        :ok = Golf.broadcast(topic, {:round_over, game})

      _ ->
        :ok
    end
  end
end
