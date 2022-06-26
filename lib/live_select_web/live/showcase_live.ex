defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

  @max_events 3

  defmodule Render do
    use Phoenix.Component

    def event(assigns) do
      cond do
        assigns[:event] ->
          ~H"""
            <p>
            def handle_event(
              <span class="text-success"><%= inspect(@event) %></span>, 
              <span class="text-primary"><%= inspect(@params) %></span>, 
              socket
            )
            </p>
          """

        assigns[:msg] ->
          ~H"""
            <p>
            def handle_info(
              <span class="text-success"><%= inspect(@msg) %></span>, 
              socket
            )
            </p>
          """
      end
    end
  end

  @impl true
  def mount(params, _session, socket) do
    cities =
      Path.expand("../../../assets/cities.json", __DIR__)
      |> File.read!()
      |> Jason.decode!()

    socket =
      assign(socket,
        change_msg: :change,
        select_msg: :select,
        cities: cities,
        events: [],
        new_event: false,
        params: nil,
        form: (params["form"] || "form") |> String.to_atom(),
        live_select_id: "live_select_with_form"
      )
      

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "update-settings",
        %{"settings" => %{"form" => form, "change_msg" => change_msg}},
        socket
      ) do
    form = form == "true"
    live_select_id = if form, do: "live_select_with_form", else: "live_select_without_form"
    
    {:noreply, assign(socket, form: form, live_select_id: live_select_id, change_msg: change_msg)}
  end

  @impl true
  def handle_event(event, params, socket) do
    Process.send_after(self(), :clear_new_event, 1_000)

    {:noreply,
     assign(socket,
       events:
         [%{params: params, event: event} | socket.assigns.events] |> Enum.take(@max_events),
       new_event: true
     )}
  end

  @impl true
  def handle_info(:clear_new_event, socket) do
    {:noreply, assign(socket, :new_event, false)}
  end

  @impl true
  def handle_info(message, socket) do
    change_msg = socket.assigns.change_msg
    select_msg = socket.assigns.select_msg

    case message do
      {^change_msg, text} ->
        send_update(LiveSelect,
          id: socket.assigns.live_select_id,
          options: cities(text, socket.assigns.cities)
        )

        Process.send_after(self(), :clear_new_event, 1_000)

        {:noreply,
         assign(socket,
           events: [%{msg: message} | socket.assigns.events] |> Enum.take(@max_events),
           new_event: true
         )}

      {^select_msg, _selected} ->
        Process.send_after(self(), :clear_new_event, 1_000)

        {:noreply,
         assign(socket,
           events: [%{msg: message} | socket.assigns.events] |> Enum.take(@max_events),
           new_event: true
         )}

      _ ->
        {:noreply, socket}
    end
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
