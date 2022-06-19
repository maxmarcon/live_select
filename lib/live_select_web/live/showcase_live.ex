defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

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
        handle_event: "",
        recent_event: false
      )

    {:ok, socket}
  end


  @impl true
  def handle_event(event, params, socket) do
    handle_event = ~s"""
              handle_event(
                  #{event}, 
                  #{inspect(params)}, 
                  socket
              )    
              """

    Process.send_after(self(), :clear_recent_event, 2000)
    
    {:noreply, assign(socket, handle_event: handle_event, recent_event: true)}
  end
  
  @impl true 
  def handle_info(:clear_recent_event, socket) do
    {:noreply, assign(socket, :recent_event, false)}
  end

  @impl true
  def handle_info(message, socket) do
    print_message(message)
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

  defp print_message(message) do
    IO.inspect(message, label: "MESSAGE")
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
