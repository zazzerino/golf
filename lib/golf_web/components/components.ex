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
        </li>
      </ol>
    </div>
    """
  end

  def opts_form(assigns) do
    ~H"""
    <div class="w-1/2 mx-auto">
      <h4 class="font-semibold text-md">Settings</h4>
      <form phx-submit={@submit} phx-change={@change} class="space-y-1">
        <.input
          name="num-rounds"
          type="number"
          min="1"
          max="32"
          label="Number of rounds"
          pattern="\d*"
          value={@num_rounds}
          required
        />
        <.button>Start Game</.button>
      </form>
    </div>
    """
  end

  def chat(assigns) do
    ~H"""
    <div class="mt-auto">
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
        class="overflow-y-auto min-h-[80px] max-h-[250px] bg-slate-100 rounded-lg"
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
      <span class="text-sm"><%= @msg.content %></span>
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
    <div class="flex flex-col my-2">
      <div class="mb-2">
        <h4 class="font-semibold text-center">Total Scores</h4>
        <.total_scores_table totals={@stats.totals} />
      </div>

      <h4 class="font-semibold text-center">Rounds</h4>
      <.round_stats_table
        :for={round <- @stats.rounds}
        num={round.num}
        turn={round.turn}
        state={round.state}
        players={round.players}
        out_username={round.player_out_username}
      />
    </div>
    """
  end

  def total_scores_table(assigns) do
    ~H"""
    <table class="min-w-[50%] mx-auto table-fixed border-separate border-spacing-y-2 border-spacing-x-2 border rounded">
      <thead class="text-sm text-center">
        <tr>
          <th :for={{username, _} <- @totals}><%= username %></th>
        </tr>
      </thead>
      <tbody class="text-center">
        <tr>
          <td :for={{_, score} <- @totals}><%= score %></td>
        </tr>
      </tbody>
    </table>
    """
  end

  def round_stats_table(assigns) do
    ~H"""
    <table class="table-auto border-separate border-spacing-1 border border-slate-200 px-2 rounded">
      <thead class="text-sm text-left">
        <tr>
          <th>Round</th>
          <th>Scores</th>
          <th>Turns</th>
          <th>1st Out</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><%= @num %></td>
          <td><.players_stats players={@players} /></td>
          <td><%= @turn %></td>
          <td><%= @out_username %></td>
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
    <li><span class="text-blue-500 font-semibold"><%= @name %></span>: <%= @score %></li>
    """
  end
end
