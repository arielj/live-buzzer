defmodule BuzzerWeb.BuzzerView do
  use BuzzerWeb, :live_view
  alias Buzzer.Presence

  @topic "users"
  @key "buzzer"

  def mount(_params, %{}, socket) do
    BuzzerWeb.Endpoint.subscribe(@topic)

    {:ok, _} = Presence.track(
      self(),
      @topic,
      @key,
      %{}
    )

    {:ok, assign(socket, invalid_name: false, name: false, current_users: current_users(), is_host: false, current_buzzer: current_buzzer())}
  end

  def users_list(assigns) do
    ~H"""
    <h1>Current users</h1>
    <ul>
      <%= for user <- @current_users do %>
        <li>
          <%= user %>
          <%= if List.first(@current_users) == user do %>
            (Host)
          <% end %>
          <%= if @current_buzzer == user do %>
            Buzzing!!
          <% end %>
        </li>
      <% end %>
    </ul>
    """
  end

  def join_form(assigns) do
    ~H"""
    <form action="" phx-submit="join" phx-change="input-changed">
      <label>
        Enter your name:
        <input type="text" name="name" />
        <%= if @invalid_name do %>
          <span>Name is invalid</span>
        <% end %>
      </label>
      <input type="submit" value="Join" disabled={@invalid_name} />
    </form>
    """
  end

  def host_actions(assigns) do
    ~H"""
    (You are the host)
    <%= if @current_buzzer do %>
      <button phx-click="clear_buzz">Clear!</button>
    <% end %>
    """
  end

  def guest_actions(assigns) do
    ~H"""
    <button phx-click="buzz" disabled={@current_buzzer}>Buzz!</button>
    """
  end

  def joined_header(assigns) do
    ~H"""
    Hi <%= @name %>!
    <%= if @is_host do %>
      <.host_actions current_buzzer={@current_buzzer} />
    <% else %>
      <.guest_actions current_buzzer={@current_buzzer} />
    <% end %>
    """
  end

  def render(assigns) do
    ~H"""
    <%= if @name do %>
      <.joined_header is_host={@is_host} current_buzzer={@current_buzzer} name={@name} />
    <% else %>
      <.join_form invalid_name={@invalid_name} />
    <% end %>

    <.users_list current_users={@current_users} current_buzzer={@current_buzzer} />
    """
  end

  defp extract_user_name(%{name: name}), do: name
  defp extract_user_name(_), do: nil

  defp extract_user_names(nil), do: []
  defp extract_user_names(metas) do
    metas
    |> Enum.map(&extract_user_name/1)
    |> Enum.filter(fn x -> x != nil end)
  end

  defp process_presence_list(list) do
    extract_user_names(list["buzzer"][:metas])
  end

  defp current_users do
    process_presence_list(Presence.list(@topic))
  end

  defp current_buzzer do
    case List.first(:ets.lookup(:buzzing, "user_name")) do
      {"user_name", name} -> name
      _ -> nil
    end
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    joining = process_presence_list(joins)
    leaving = process_presence_list(leaves)
    new_current_users = (socket.assigns.current_users ++ joining) -- leaving

    is_host = List.first(new_current_users) == socket.assigns.name

    {:noreply, assign(socket, current_users: new_current_users, is_host: is_host)}
  end

  def handle_info(%{event: "buzzer_pressed"}, socket) do
    {:noreply, assign(socket, current_buzzer: current_buzzer())}
  end

  def handle_info(%{event: "buzzer_cleared"}, socket) do
    {:noreply, assign(socket, current_buzzer: nil)}
  end

  def handle_event("buzz", _, socket) do
    if !current_buzzer() do
      :ets.insert(:buzzing, {"user_name", socket.assigns.name})
      BuzzerWeb.Endpoint.broadcast!(@topic, "buzzer_pressed", %{})
    end
    {:noreply, socket}
  end

  def handle_event("clear_buzz", _, socket) do
    if current_buzzer() do
      :ets.delete(:buzzing, "user_name")
      BuzzerWeb.Endpoint.broadcast!(@topic, "buzzer_cleared", %{})
    end
    {:noreply, socket}
  end

  def handle_event("join", %{"name" => name}, socket) do
    name = String.trim(name)

    if String.match?(name, ~r/\A\s*\z/) do
      {:noreply, assign(socket, invalid_name: true)}
    else
      Presence.update(self(), @topic, @key, %{name: name})
      {:noreply, assign(socket, name: name)}
    end
  end

  def handle_event("input-changed", %{"_target" => ["name"], "name" => name}, socket) do
    {:noreply, assign(socket, invalid_name: String.match?(name, ~r/\A\s*\z/))}
  end
end
