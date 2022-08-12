defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

  import LiveSelect
  alias LiveSelect.ChangeMsg

  @max_events 3

  # valid params with default values
  @params [
    active_option_class: nil,
    container_class: nil,
    container_extra_class: nil,
    disabled: nil,
    dropdown_class: nil,
    dropdown_extra_class: nil,
    field_name: "city_search",
    form_name: "my_form",
    placeholder: "Search for a city",
    search_term_min_length: 3,
    style: :daisyui,
    text_input_class: nil,
    text_input_extra_class: nil,
    text_input_selected_class: nil,
    search_delay: 0
  ]

  defmodule Render do
    @moduledoc false

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
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        events: [],
        new_event: false,
        params: @params,
        selected: nil,
        selected_text: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    params = Map.reject(params, fn {_param, value} -> value == "" end)

    socket =
      socket
      |> assign(:form_name, params["form_name"] || @params[:form_name])
      |> assign(:field_name, params["field_name"] || @params[:field_name])
      |> assign(
        :search_delay,
        (params["search_delay"] && String.to_integer(params["search_delay"])) ||
          @params[:search_delay]
      )
      |> assign(:live_select_opts, live_select_opts(params))

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "update-settings",
        %{"settings" => settings},
        socket
      ) do
    socket =
      socket
      |> push_patch(to: Routes.live_path(socket, __MODULE__, settings))

    {:noreply, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    Process.send_after(self(), :clear_new_event, 1_000)

    socket =
      if event == "submit" do
        selected = get_in(params, [socket.assigns.form_name, socket.assigns.field_name])

        selected_text =
          get_in(params, [socket.assigns.form_name, socket.assigns.field_name <> "_text_input"])

        assign(socket, selected: selected, selected_text: selected_text)
      else
        socket
      end

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

  def handle_info({:update_live_select, change_msg, options}, socket) do
    update_options(change_msg, options)

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    case message do
      %ChangeMsg{text: text} = change_msg ->
        Process.send_after(self(), :clear_new_event, 1_000)

        Process.send_after(
          self(),
          {:update_live_select, change_msg, change_handler().handle_change(text)},
          socket.assigns.search_delay
        )

        {:noreply,
         assign(socket,
           events: [%{msg: message} | socket.assigns.events] |> Enum.take(@max_events),
           new_event: true
         )}

      _ ->
        {:noreply, socket}
    end
  end

  defp live_select_opts(params) do
    string_keys = Keyword.keys(@params) |> Enum.map(&to_string/1)

    params =
      params
      |> Map.take(string_keys)
      |> Keyword.new(fn {param, value} ->
        value =
          cond do
            param == "search_term_min_length" -> String.to_integer(value)
            param == "style" -> String.to_atom(value)
            true -> value
          end

        {String.to_atom(param), value}
      end)

    @params
    |> Keyword.merge(Application.get_env(:live_select, :default_styles, []))
    |> Enum.reduce(params, fn {param, default}, params ->
      Keyword.put_new(params, param, default)
    end)
  end

  defp change_handler() do
    Application.get_env(:live_select, :change_handler) ||
      raise "you need to specify a :change_handler in your :live_select config"
  end
end
