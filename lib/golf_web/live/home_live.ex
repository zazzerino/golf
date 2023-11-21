defmodule GolfWeb.HomeLive do
  use GolfWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <h2>Home</h2>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
