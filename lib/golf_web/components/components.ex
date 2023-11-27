defmodule GolfWeb.Components do
  use Phoenix.Component
  import GolfWeb.CoreComponents

  def join_lobby_form(assigns) do
    ~H"""
    <form phx-submit={@submit} class="w-1/4 mx-auto">
      <.input name="id" value="" placeholder="Game ID" required />
      <.button class="w-full">Join Game</.button>
    </form>
    """
  end

  def players_list(assigns) do
    ~H"""
    <div class="flex-none w-1/2 mx-auto">
      <h4 class="font-semibold text-md">Players</h4>
      <ol id="players-list" phx-update="stream" class="p-2">
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
    <div class="w-1/2 mx-auto">
      <h4 class="font-semibold text-md">Settings</h4>
      <form phx-submit={@submit} class="space-y-1">
        <.input name="num-rounds" type="number" min="1" max="50" label="Number of rounds" value="1" />
        <.button>Start Game</.button>
      </form>
    </div>
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
        <.chat_message :for={{id, msg} <- @messages} id={id} msg={msg} />
      </ul>
    </div>
    """
  end

  defp chat_message(assigns) do
    ~H"""
    <li id={@id} class="text-left">
      <span class="text-xs text-green-500"><%= @msg.inserted_at %></span>
      <span class="font-semibold text-violet-500"><%= @msg.user.name %></span>:
      <span><%= @msg.content %></span>
    </li>
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

  def game_stats(assigns) do
    ~H"""
    <div class="">
      <.round_stats_table
        :for={{round, i} <- Enum.with_index(@stats.rounds, 1)}
        num={i}
        turn={round.turn}
        state={round.state}
        players={round.players}
      />
    </div>
    """
  end

  def round_stats_table(assigns) do
    ~H"""
    <table class="table-auto w-3/5 border-separate text-center mx-auto">
      <thead class="text-sm text-center font-semibold">
        <tr>
          <th>Round</th>
          <th>Turns</th>
          <th>Scores</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><%= @num %></td>
          <td><%= @turn %></td>
          <td><.players_stats players={@players} /></td>
        </tr>
      </tbody>
    </table>
    """
  end

  def players_stats(assigns) do
    ~H"""
    <ol>
      <.player_stats :for={p <- @players} name={p.user.name} score={p.score} />
    </ol>
    """
  end

  def player_stats(assigns) do
    ~H"""
    <li><%= "#{@name}: #{@score}" %></li>
    """
  end
end
