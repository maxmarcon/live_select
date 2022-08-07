defmodule LiveSelect.Component do
  @moduledoc false

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form

  @default_opts [
    msg_prefix: "live_select",
    search_term_min_length: 3,
    field: "live_select",
    container_class: ~S(dropdown w-full),
    text_input_class: ~S(input input-bordered w-full),
    text_input_selected_class: ~S(input-primary text-primary),
    dropdown_class:
      ~S(dropdown-content menu menu-compact p-2 shadow bg-base-200 rounded-box w-full),
    active_option_class: ~S(active)
  ]

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(
        current_focus: -1,
        disabled: false,
        dropdown_mouseover: false,
        form: nil,
        options: [],
        placeholder: "Type to search...",
        search_term: "",
        selected: nil
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:current_focus, -1)
      |> update(:options, &normalize_options/1)

    socket =
      Enum.reduce(@default_opts, socket, fn {opt, default}, socket ->
        if socket.assigns[opt] do
          socket
        else
          assign(socket, opt, default)
        end
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("click", _params, socket) do
    socket =
      if socket.assigns.selected && !socket.assigns.disabled do
        reset_input(socket)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keyup", %{"value" => search_term, "key" => key}, socket)
      when key not in ["ArrowDown", "ArrowUp", "Enter", "Tab"] do
    socket =
      if socket.assigns.selected do
        socket
      else
        if String.length(search_term) >= socket.assigns.search_term_min_length do
          send(
            self(),
            {msg(socket, "change"),
             %{module: __MODULE__, id: socket.assigns.id, text: search_term}}
          )

          socket
        else
          assign(socket, :options, [])
        end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keyup", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    if socket.assigns.dropdown_mouseover do
      {:noreply, socket}
    else
      {:noreply,
       assign(
         socket,
         :current_focus,
         min(length(socket.assigns.options) - 1, socket.assigns.current_focus + 1)
       )}
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    if socket.assigns.dropdown_mouseover do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :current_focus, max(0, socket.assigns.current_focus - 1))}
    end
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    socket =
      if socket.assigns.selected do
        reset_input(socket)
      else
        select(socket, socket.assigns.current_focus)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_event("option-click", %{"idx" => idx}, socket) do
    {:noreply, select(socket, String.to_integer(idx))}
  end

  @impl true
  def handle_event("dropdown-mouseover", _params, socket) do
    {:noreply, assign(socket, current_focus: -1, dropdown_mouseover: true)}
  end

  @impl true
  def handle_event("dropdown-mouseleave", _params, socket) do
    {:noreply, assign(socket, dropdown_mouseover: false)}
  end

  defp select(socket, -1), do: socket

  defp select(socket, selected_position) do
    {label, selected} = Enum.at(socket.assigns.options, selected_position)

    socket =
      socket
      |> assign(
        options: [],
        current_focus: -1,
        search_term: label,
        selected: selected
      )
      |> push_event("selected", %{selected: [label, selected]})

    socket
  end

  defp reset_input(socket) do
    socket
    |> assign(options: [], selected: nil, search_term: "")
    |> push_event("reset", %{})
  end

  defp msg(socket, msg),
    do: "#{socket.assigns.msg_prefix}_#{msg}"

  defp normalize_options(option_list) do
    option_list
    |> Enum.map(fn
      option when is_list(option) ->
        {option[:key], option[:value]}

      {_key, _value} = option ->
        option

      option when is_binary(option) or is_atom(option) or is_integer(option) ->
        {option, option}

      option ->
        raise "invalid option: #{option}"
    end)
  end
end
