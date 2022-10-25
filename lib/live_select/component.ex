defmodule LiveSelect.Component do
  @moduledoc false

  alias LiveSelect.ChangeMsg

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form
  import LiveSelect.ClassUtil

  @default_opts [
    active_option_class: nil,
    container_class: nil,
    container_extra_class: nil,
    debounce: 100,
    disabled: false,
    dropdown_class: nil,
    dropdown_extra_class: nil,
    option_class: nil,
    option_extra_class: nil,
    placeholder: nil,
    update_min_len: 3,
    style: :tailwind,
    text_input_class: nil,
    text_input_extra_class: nil,
    text_input_selected_class: nil
  ]

  @styles [
    daisyui: [
      active_option: ~S(active),
      container: ~S(dropdown dropdown-open),
      dropdown: ~S(dropdown-content menu menu-compact shadow rounded-box bg-base-200 p-1 w-full),
      text_input: ~S(input input-bordered w-full),
      text_input_selected: ~S(input-primary text-primary)
    ],
    tailwind: [
      active_option: ~S(text-white bg-gray-600),
      container: ~S(relative h-full text-black),
      dropdown: ~S(absolute rounded-xl shadow z-50 bg-gray-100 w-full),
      option: ~S(rounded-lg px-4 py-1 hover:bg-gray-400),
      text_input:
        ~S(rounded-md h-full w-full disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400),
      text_input_selected: ~S(border-gray-600 text-gray-600 border-2)
    ],
    none: []
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
        input: "",
        selected: nil,
        hide_dropdown: false
      )

    {:ok, socket}
  end

  @doc false
  def default_opts(), do: @default_opts

  @doc false
  def default_class(style, class) do
    element =
      String.replace_trailing(to_string(class), "_class", "")
      |> String.to_atom()

    get_in(@styles, [style, element])
  end

  @impl true
  def update(assigns, socket) do
    validate_options!(assigns)

    socket =
      socket
      |> assign(assigns)
      |> assign(:current_focus, -1)
      |> update(:options, &normalize_options/1)

    socket =
      @default_opts
      |> Enum.reduce(socket, fn {opt, default}, socket ->
        socket
        |> assign_new(opt, fn -> default end)
      end)
      |> update(:update_min_len, fn
        nil -> @default_opts[:update_min_len]
        val -> val
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

    {:noreply, assign(socket, :hide_dropdown, false)}
  end

  @impl true
  def handle_event("click_away", _params, socket) do
    {:noreply, assign(socket, :hide_dropdown, true)}
  end

  @impl true
  def handle_event("blur", _params, socket) do
    {:noreply, assign(socket, :hide_dropdown, !socket.assigns.dropdown_mouseover)}
  end

  @impl true
  def handle_event("focus", _params, socket) do
    {:noreply, assign(socket, :hide_dropdown, false)}
  end

  @impl true
  def handle_event("keyup", %{"value" => text, "key" => key}, socket)
      when key not in ["ArrowDown", "ArrowUp", "Enter", "Tab"] do
    socket =
      if socket.assigns.selected do
        socket
      else
        if String.length(text) >=
             socket.assigns.update_min_len do
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

  defp validate_options!(assigns) do
    if style = assigns[:style] do
      unless style in Keyword.keys(@styles) do
        raise(
          ~s(Invalid style: "#{assigns.style}". Style must be one of: #{inspect(Keyword.keys(@styles))})
        )
      end
    end

    valid_assigns = Keyword.keys(@default_opts) ++ [:field, :form, :id, :options]

    for {option, _} <- assigns_to_attributes(assigns) do
      unless option in valid_assigns do
        most_similar =
          (valid_assigns -- [:field, :form, :id, :options])
          |> Enum.sort_by(&String.jaro_distance(to_string(&1), to_string(option)))
          |> List.last()

        raise ~s(Invalid option: "#{option}". Did you mean "#{most_similar}" ?)
      end
    end
  end

  defp select(socket, -1), do: socket

  defp select(socket, selected_position) do
    {label, selected} = Enum.at(socket.assigns.options, selected_position)

    socket
    |> assign(
      options: [],
      current_focus: -1,
      input: label,
      selected: selected,
      dropdown_mouseover: false
    )
    |> push_event("selected", %{id: socket.assigns.id, selected: [label, selected]})
  end

  defp reset_input(socket) do
    socket
    |> assign(options: [], selected: nil, input: "")
    |> push_event("reset", %{id: socket.assigns.id})
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

  defp class(:none, element, nil, _class_extend) do
    raise """
    When using `style: :none`, please use only `#{element}_class` and not `#{element}_extra_class`
    """
  end

  defp class(style, element, nil, class_extend) do
    extend(
      get_in(@styles, [style, element]) || "",
      class_extend
    )
  end

  defp class(_style, element, _class_override, _class_extend) do
    raise """
    You specified both `#{element}_class` and `#{element}_extra_class` options.
    The `#{element}_class` and `#{element}_extra_class` options can't be used together.
    Use `#{element}_class` if you want to completely override the default class for `#{element}`.
    Use `#{element}_extra_class` if you want to extend the default class for the element with additional classes.
    """
  end
end
