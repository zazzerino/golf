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
    <div class="flex-none">
      <h4 class="font-semibold text-md">Players</h4>
      <ol id="players-list" phx-update="stream" class="bg-green-200 p-2">
        <li :for={{dom_id, user} <- @users} id={dom_id}>
          <span class="text-blue-500 font-semibold">
            <%= user.name %>
          </span>
          <span class="text-xs">(id=<%= user.id %>)</span>
        </li>
      </ol>
    </div>
    """
  end

  def opts_form(assigns) do
    ~H"""
    <div>
      <h4 class="font-semibold text-md">Settings</h4>
      <form phx-submit={@submit} class="space-y-1">
        <.input name="num-rounds" type="number" min="1" max="50" label="Number of rounds" value="1" />
        <.button>Start Game</.button>
      </form>
    </div>
    """
  end

  def game_header(assigns) do
    ~H"""
    <h2>
      <span class="font-bold">Game</span> <%= @id %>
    </h2>
    """
  end

  def chat(assigns) do
    ~H"""
    <div class="flex-auto">
      <.chat_messages messages={@messages} />
      <.chat_form submit={@submit} />
    </div>
    """
  end

  def chat_messages(assigns) do
    ~H"""
    <div class="">
      <h4 class="font-semibold text-md">Messages</h4>
      <ul
        id="chat-messages"
        phx-update="stream"
        class="overflow-y-auto min-h-[5rem] max-h-[175px] bg-slate-100 rounded-lg"
      >
        <li :for={{dom_id, msg} <- @messages} id={dom_id}>
          <span class="text-xs text-green-500"><%= msg.inserted_at %></span>
          <span class="font-semibold text-violet-500"><%= msg.user.name %></span>:
          <span><%= msg.content %></span>
        </li>
      </ul>
    </div>
    """
  end

  def chat_form(assigns) do
    ~H"""
    <form phx-submit={@submit} class="space-y-1">
      <.input
        id="chat-form-input"
        name="content"
        value=""
        placeholder="Type chat message here..."
        required
      />
      <.button>Submit</.button>
    </form>
    """
  end

  def player_scores(assigns) do
    ~H"""
    <table class="">
      <thead class="text-sm text-left">
        <tr>
          <th>User</th>
          <th>Score</th>
        </tr>
      </thead>
      <tbody>
        <tr :for={p <- @players}>
          <td><%= p.user.name %></td>
          <td><%= p.score %></td>
        </tr>
      </tbody>
    </table>
    """
  end
end
