defmodule LiveSelect.Component do
  @moduledoc false

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form

  alias LiveSelect.ChangeMsg

  @default_opts [
    active_option_class: nil,
    container_class: nil,
    container_extra_class: nil,
    dropdown_class: nil,
    dropdown_extra_class: nil,
    disabled: false,
    debounce: 100,
    placeholder: nil,
    search_term_min_length: 3,
    style: :daisyui,
    text_input_class: nil,
    text_input_extra_class: nil,
    text_input_selected_class: nil
  ]

  @styles [
    daisyui: [
      container: ~S(dropdown),
      text_input: ~S(input input-bordered),
      text_input_selected: ~S(input-primary text-primary),
      dropdown: ~S(dropdown-content menu menu-compact shadow rounded-box),
      active_option: ~S(active)
    ]
  ]

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(
        current_focus: -1,
        disabled: false,
        dropdown_mouseover: false,
        options: [],
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
        assign_new(socket, opt, fn -> default end)
      end)
      |> assign(:text_input_field, String.to_atom("#{socket.assigns.field}_text_input"))

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
  def handle_event("keyup", %{"value" => text, "key" => key}, socket)
      when key not in ["ArrowDown", "ArrowUp", "Enter", "Tab"] do
    socket =
      if socket.assigns.selected do
        socket
      else
        if String.length(text) >= socket.assigns.search_term_min_length do
          send(
            self(),
            %ChangeMsg{
              module: __MODULE__,
              id: socket.assigns.id,
              text: text,
              field: socket.assigns.field
            }
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

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
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

  defp normalize_options(options) do
    options
    |> Enum.map(fn
      option when is_list(option) or is_map(option) ->
        {option[:label] || option[:key], option[:value]}

      {_key, _value} = option ->
        option

      option when is_binary(option) or is_atom(option) or is_integer(option) ->
        {option, option}

      option ->
        raise """
        invalid option: #{inspect(option)}
        options must enumerate to:

        a list of atom, strings or numbers
        a list of maps or keywords with label and value keys
        a list of tuples
        """
    end)
  end

  defp class(style, element, class_override, class_extend \\ nil)

  defp class(style, element, nil, nil) do
    get_in(@styles, [style, element])
  end

  defp class(_style, _element, class_override, nil) do
    class_override
  end

  defp class(style, element, nil, class_extend) do
    (get_in(@styles, [style, element]) || "") <> " #{class_extend}"
  end
end
