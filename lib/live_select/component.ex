defmodule LiveSelect.Component do
  @moduledoc "This is LiveSelect main module"

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(
        class: "dropdown w-full",
        current_focus: -1,
        disabled: false,
        dropdown_mouseover: false,
        form: nil,
        input_field: :live_select,
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

    socket =
      Enum.reduce(default_opts(), socket, fn {opt, default}, socket ->
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
  def handle_event("enter", _params, socket) do
    socket =
      if socket.assigns.selected do
        reset_input(socket)
      else
        select(socket, socket.assigns.current_focus)
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
          send(self(), {msg(socket, "change"), search_term})
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
  def handle_event("results-down", _params, socket) do
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
  def handle_event("results-up", _params, socket) do
    if socket.assigns.dropdown_mouseover do
      {:noreply, socket}
    else
      {:noreply, assign(socket, :current_focus, max(0, socket.assigns.current_focus - 1))}
    end
  end

  @impl true
  def handle_event("select", %{"idx" => idx}, socket) do
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

  defp default_opts() do
    [
      msg_prefix: "live_select",
      search_term_min_length: 3
    ]
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
end
