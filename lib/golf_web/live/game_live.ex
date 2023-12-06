defmodule GolfWeb.GameLive do
  use GolfWeb, :live_view

  import GolfWeb.Components, only: [chat: 1, game_stats: 1, game_button: 1]

  alias Golf.{Games, GamesDb, Chat}
  alias Golf.Games.{Player, Event}
  alias Golf.Games.ClientData, as: Data

  # @impl true
  # def render(assigns) do
  #   ~H"""
  #   <div class="mx-auto w-[480px] sm:w-[600px]">
  #     <h1 class="text-zinc-800 text-center">
  #       <div>
  #         <span class="text-lg font-bold">Game</span>
  #         <span class="text-green-500 font-semibold copyable hover:cursor-pointer hover:underline">
  #           <%= @id %>
  #         </span>
  #       </div>
  #     </h1>

  #     <div class="origin-top-left scale-x-[80%] scale-y-[80%] sm:scale-x-100 sm:scale-y-100">
  #       <div id="game-canvas" phx-hook="GameCanvas" phx-update="ignore"></div>
  #     </div>

  #     <div class="mt-[-7rem] sm:mt-1">
  #       <.button :if={@can_start_game?} phx-click="start-game">
  #         Start Game
  #       </.button>

  #       <.button :if={@can_start_round?} phx-click="start-round">
  #         Start Round
  #       </.button>
  #     </div>

  #     <div :if={@game_over?} class="font-semibold text-center text-xl">Game Over</div>

  #     <div :if={@game} class="flex flex-col">
  #       <.game_stats stats={Games.game_stats(@game)} />
  #       <.chat messages={@streams.chat_messages} submit="submit-chat" />
  #     </div>
  #   </div>
  #   """
  # end

  # min-w-[470px] min-h-[585px]

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
          "mb-2 min-w-[300px] max-h-[calc(100vh-1.5rem)] flex flex-col",
          "px-4 space-y-4 divide-y whitespace-nowrap"
        ]}
      >
        <.game_stats class="max-h-[42vh] overflow-y-auto" stats={Games.game_stats(@game)} />
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

  def info_switch(assigns) do
    ~H"""
    <label
      id="info-switch"
      class="top-[95%] left-[98%] translate-x-[-100%] absolute inline-flex items-center cursor-pointer"
    >
      <input
        checked={not @show_info?}
        phx-click="toggle-info"
        id="info-toggle"
        type="checkbox"
        value=""
        class="sr-only peer"
      />
      <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600">
      </div>
      <span class="ms-3 text-sm font-medium text-gray-900 dark:text-gray-300">Hide</span>
    </label>
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
    {:noreply,
     socket
     |> assign(:show_info?, not socket.assigns.show_info?)
     |> push_event("resize-canvas", %{})}
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
