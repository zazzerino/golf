defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.Components, only: [chat: 1, game_stats: 1, game_button: 1, info_switch: 1]

  alias Golf.{Games, GamesDb, Chat}
  alias Golf.Games.{Player, Event}
  alias Golf.Games.ClientData, as: Data

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex flex-row ">
      <div class="relative min-w-0 flex-auto h-[calc(100vh-1.5rem)]">
        <div class="w-full h-full" id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>

        <div class="absolute top-[90%] left-1/2 translate-x-[-50%] translate-y-[-50%]">
          <.game_button :if={@can_start_game?} phx-click="start-game">
            Start Game
          </.game_button>

          <.game_button :if={@can_start_round?} phx-click="start-round">
            Start Round
          </.game_button>
        </div>
      </div>

      <div
        :if={@game && @show_info?}
        id="game-info"
        class={[
          "min-w-[40vw] max-h-[calc(100vh-2.5rem)] flex flex-col",
          "px-4 space-y-4 divide-y whitespace-nowrap mb-1"
        ]}
      >
        <div :if={@game_over?} class="text-center font-semibold text-lg mt-1 mb-[-0.5rem]">
          Game Over
        </div>
        <.game_stats
          class="max-h-[calc(50vh-1.5rem)] overflow-y-auto"
          stats={Games.game_stats(@game)}
        />
        <.chat
          class="mt-auto bg-white flex flex-col"
          messages={@streams.chat_messages}
          submit="submit-chat"
        />
      </div>

      <.info_switch show_info?={@show_info?} />
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
       can_start_game?: nil,
       can_start_round?: nil,
       round_over?: nil,
       game_over?: nil,
       name_colors: %{},
       show_info?: true
       #  chat_messages: []
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
           can_start_game?: host? and data.state == :no_round,
           can_start_round?: host? and data.state == :round_over,
           round_over?: data.state == :round_over,
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
    # {:noreply, assign(socket, :chat_messages, messages)}
  end

  @impl true
  def handle_info({:new_chat_message, message}, socket) do
    {:noreply, stream_insert(socket, :chat_messages, message, at: 0)}
    # {:noreply, assign(socket, :chat_messages, [message | socket.assigns.chat_messages])}
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
     assign(socket, game: game, can_start_round?: false, round_over?: false)
     |> push_event("round-started", %{"game" => data})}
  end

  @impl true
  def handle_info({:game_event, game, event}, socket) do
    data = Data.from(game, socket.assigns.current_user)

    {:noreply,
     assign(socket, game: game)
     |> push_event("game-event", %{"game" => data, "event" => event})}
  end

  @impl true
  def handle_info({:round_over, game}, socket) do
    can_start_round? = socket.assigns.current_user.id == game.host_id

    {:noreply,
     assign(socket, can_start_round?: can_start_round?, round_over?: true)
     |> push_event("round-over", %{})}
  end

  @impl true
  def handle_info({:game_over, _game}, socket) do
    {:noreply,
     assign(socket, game_over?: true)
     |> push_event("game-over", %{})}
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

    message = Map.update!(message, :inserted_at, &Chat.format_chat_time/1)

    :ok = Golf.broadcast("chat:#{id}", {:new_chat_message, message})
    {:noreply, push_event(socket, "clear-chat-input", %{})}
  end

  @impl true
  def handle_event("toggle-info", _params, socket) do
    unless socket.assigns.show_info? do
      messages = Golf.Chat.get_messages(socket.assigns.id)

      {:noreply,
       socket
       |> assign(show_info?: not socket.assigns.show_info?)
       |> stream(:chat_messages, messages, at: 0)
       |> push_event("resize-canvas", %{})}
    else
      {:noreply,
       socket
       |> assign(show_info?: not socket.assigns.show_info?)
       |> push_event("resize-canvas", %{})}
    end
  end

  defp action_at(state, "hand") when state in [:flip_2, :flip], do: :flip
  defp action_at(:take, "table"), do: :take_table
  defp action_at(:take, "deck"), do: :take_deck
  defp action_at(:hold, "table"), do: :discard
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
