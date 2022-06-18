defmodule LiveSelect do
  @moduledoc false

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(
        options: [],
        change_msg: :search,
        select_msg: :select,
        search_term: "",
        selected: false,
        disabled: false,
        placeholder: "Type to search...",
        form: :form,
        options: [],
        dropdown_mouseover: false,
        current_focus: -1
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, Map.put(assigns, :current_focus, -1))}
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
  def handle_event("keyup", %{"value" => search_term, "key" => key} = _params, socket)
      when key not in ["ArrowDown", "ArrowUp", "Enter", "Tab"] do
    socket =
      if socket.assigns.selected do
        socket
      else
        if String.length(search_term) > 2 do
          send(self(), {socket.assigns.change_msg, search_term})
        end

        socket
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
end
