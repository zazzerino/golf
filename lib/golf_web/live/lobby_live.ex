defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view
  import GolfWeb.Components, only: [players_list: 1, opts_form: 1]
  alias Golf.Games.Opts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2>
        <span class="font-bold">Lobby</span> <%= @id %>
      </h2>

      <.players_list users={@streams.users} />
      <.opts_form submit="start-game" />
    </div>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      send(self(), {:load_lobby, id})
    end

    {:ok,
     assign(socket,
       page_title: "Lobby",
       id: id,
       lobby: nil,
       can_join?: nil
     )
     |> stream(:users, [])}
  end

  @impl true
  def handle_info({:load_lobby, id}, socket) do
    case Golf.Lobbies.get_lobby(id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Lobby #{id} not found.")
         |> push_navigate(to: ~p"/")}

      lobby ->
        :ok = Golf.subscribe("lobby:#{id}")

        {:noreply,
         assign(socket, lobby: lobby)
         |> stream(:users, lobby.users)}
    end
  end

  @impl true
  def handle_info({:user_joined, lobby, new_user}, socket) do
    can_join? = not Enum.any?(lobby.users, &(&1.id == socket.assigns.current_user.id))

    {:noreply,
     socket
     |> assign(lobby: lobby, can_join?: can_join?)
     |> stream(:users, lobby.users)
     # TODO
     # |> stream_insert(:users, new_user)
     |> put_flash(:info, "User joined: #{new_user.email}(id=#{new_user.id})")}
  end

  @impl true
  def handle_info({:game_created, game}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/game/#{game.id}")}
  end

  @impl true
  def handle_event("start-game", params, socket) do
    id = socket.assigns.id

    unless Golf.GamesDb.game_exists?(id) do
      %{valid?: true} = opts_cs = Opts.changeset(%Opts{}, params)
      users = socket.assigns.lobby.users
      {:ok, game} = Golf.GamesDb.create_game(id, users, opts_cs.data)
      :ok = Golf.broadcast("lobby:#{id}", {:game_created, game})
    end

    {:noreply, push_navigate(socket, to: ~p"/game/#{id}")}
  end
end
