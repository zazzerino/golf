defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view
  import GolfWeb.Components, only: [join_lobby_form: 1]

  # we need the id length as a constant in this module so we can use it in guards
  @id_length Golf.id_length()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="font-bold">Home</h2>

      <p :if={!@current_user}>
        <.register_link /> or <.login_link /> to play.
      </p>

      <.button :if={@current_user} phx-click="create-lobby">
        Create Game
      </.button>

      <.join_lobby_form :if={@current_user} submit="join-lobby" />
    </div>
    """
  end

  defp register_link(assigns) do
    ~H"""
    <.link navigate={~p"/users/register"} class="text-blue-500 underline">Register</.link>
    """
  end

  defp login_link(assigns) do
    ~H"""
    <.link navigate={~p"/users/log_in"} class="text-blue-500 underline">Login</.link>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def handle_event("create-lobby", _params, socket) do
    id = Golf.gen_id()
    {:ok, _} = Golf.Lobbies.create_lobby(id, socket.assigns.current_user)
    {:noreply, push_navigate(socket, to: ~p"/lobby/#{id}")}
  end

  @impl true
  def handle_event("join-lobby", %{"id" => id}, socket) when byte_size(id) != @id_length do
    message = "Game ID should be #{@id_length} chars long."
    {:noreply, put_flash(socket, :error, message)}
  end

  @impl true
  def handle_event("join-lobby", %{"id" => id}, socket) do
    case Golf.Lobbies.get_lobby(String.downcase(id)) do
      nil ->
        {:noreply, put_flash(socket, :error, "Lobby #{id} not found.")}

      lobby ->
        user = socket.assigns.current_user
        {:ok, lobby} = Golf.Lobbies.add_lobby_user(lobby, user)
        :ok = Golf.broadcast("lobby:#{id}", {:user_joined, lobby, user})
        {:noreply, push_navigate(socket, to: ~p"/lobby/#{id}")}
    end
  end
end
