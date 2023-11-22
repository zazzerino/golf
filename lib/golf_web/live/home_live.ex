defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <h2 class="font-bold">Home</h2>

      <.button :if={@current_user} phx-click="create-lobby">
        Create Game
      </.button>
    </div>
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
end
