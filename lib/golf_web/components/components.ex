defmodule GolfWeb.Components do
  use Phoenix.Component
  import GolfWeb.CoreComponents

  def join_lobby_form(assigns) do
    ~H"""
    <form phx-submit={@submit} class="space-y-2">
      <.input name="id" value="" placeholder="Game ID" required />
      <.button>Join Game</.button>
    </form>
    """
  end

  def players_list(assigns) do
    ~H"""
    <div>
      <h4 class="font-bold text-sm">Players</h4>
      <ol>
        <li :for={{_, u} <- @users}>
          User(id=<%= u.id %>, email=<%= u.email %>)
        </li>
      </ol>
    </div>
    """
  end

  def opts_form(assigns) do
    ~H"""
    <div>
      <h4 class="font-bold text-sm">Opts</h4>
      <form phx-submit={@submit} class="space-y-1">
        <.input name="num-rounds" type="number" min="1" max="50" label="Number of rounds" value="1" />
        <.button>Start Game</.button>
      </form>
    </div>
    """
  end
end
