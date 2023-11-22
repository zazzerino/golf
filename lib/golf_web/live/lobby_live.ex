defmodule GolfWeb.LobbyLive do
  use GolfWeb, :live_view
  import GolfWeb.Components, only: [users_list: 1, opts_form: 1]
  alias Golf.Games.Opts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2>
        <span class="font-bold">Lobby</span> <%= @id %>
      </h2>

      <.users_list users={@streams.users} />
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
     socket
     |> assign(
       page_title: "Lobby",
       id: id,
       lobby: nil
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
         socket
         |> assign(lobby: lobby)
         |> stream(:users, lobby.users)}
    end
  end

  @impl true
  def handle_event("start-game", params, socket) do
    %{valid?: true} = opts_cs = Opts.changeset(%Opts{}, params)

    {:ok, _game} =
      Golf.GamesDb.create_game(
        socket.assigns.id,
        [socket.assigns.current_user],
        opts_cs.data
      )

    {:noreply, socket}
  end
end
