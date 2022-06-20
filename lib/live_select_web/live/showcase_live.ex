defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

  defmodule Util do
    use Phoenix.Component

    def handle_event(assigns) do
      ~H"""
      <p>
      def handle_event(
        <span class="text-success"><%= inspect(@event) %></span>, 
        <span class="text-primary"><%= inspect(@params) %></span>, 
        socket
      )
      </p>
      """
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    cities =
      Path.expand("../../../assets/cities.json", __DIR__)
      |> File.read!()
      |> Jason.decode!()

    socket =
      assign(socket,
        change_msg: :change,
        cities: cities,
        event: nil,
        params: nil,
        recent_event: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    Process.send_after(self(), :clear_recent_event, 2000)

    {:noreply,
     assign(socket, event: event, params: params |> Map.take(["form"]), recent_event: true)}
  end

  @impl true
  def handle_info(:clear_recent_event, socket) do
    {:noreply, assign(socket, :recent_event, false)}
  end

  @impl true
  def handle_info(message, socket) do
    change_msg = socket.assigns.change_msg

    case message do
      {^change_msg, text} ->
        send_update(LiveSelect,
          id: "live_select",
          options: cities(text, socket.assigns.cities)
        )

      _ ->
        IO.puts("unknown message")
    end

    {:noreply, socket}
  end

  defp cities("", _cities), do: []

  defp cities(text, cities) do
    cities
    |> Enum.filter(fn %{"name" => name} ->
      String.contains?(String.downcase(name), String.downcase(text))
    end)
    |> Enum.map(fn %{"name" => name, "loc" => %{"coordinates" => coord}} ->
      {name, coord}
    end)
  end
end
