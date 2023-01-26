defmodule LiveSelect.Component do
  @moduledoc "The module that implements the `LiveSelect` live component"

  alias LiveSelect.ChangeMsg

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form, only: [text_input: 3, input_id: 2, input_name: 2, input_value: 2]
  import LiveSelect.ClassUtil

  @default_opts [
    active_option_class: nil,
    available_option_class: nil,
    user_defined_options: false,
    container_class: nil,
    container_extra_class: nil,
    debounce: 100,
    disabled: false,
    dropdown_class: nil,
    dropdown_extra_class: nil,
    max_selectable: 0,
    mode: :single,
    option_class: nil,
    option_extra_class: nil,
    options: [],
    placeholder: nil,
    selected_option_class: nil,
    style: :tailwind,
    tag_class: nil,
    tag_extra_class: nil,
    tags_container_class: nil,
    tags_container_extra_class: nil,
    text_input_class: nil,
    text_input_extra_class: nil,
    text_input_selected_class: nil,
    update_min_len: 3,
    value: nil
  ]

  @styles [
    tailwind: [
      active_option: ~S(text-white bg-gray-600),
      available_option: ~S(cursor-pointer hover:bg-gray-400 rounded),
      container: ~S(relative h-full text-black),
      dropdown: ~S(absolute rounded-md shadow z-50 bg-gray-100 w-full),
      option: ~S(rounded px-4 py-1),
      selected_option: ~S(text-gray-400),
      text_input:
        ~S(rounded-md w-full disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400),
      text_input_selected: ~S(border-gray-600 text-gray-600),
      tags_container: ~S(flex flex-wrap gap-1 p-1),
      tag: ~S(p-1 text-sm rounded-lg bg-blue-400 flex)
    ],
    daisyui: [
      active_option: ~S(active),
      available_option: ~S(cursor-pointer),
      container: ~S(dropdown dropdown-open),
      dropdown: ~S(dropdown-content menu menu-compact shadow rounded-box bg-base-200 p-1 w-full),
      option: nil,
      selected_option: ~S(disabled),
      text_input: ~S(input input-bordered w-full),
      text_input_selected: ~S(input-primary),
      tags_container: ~S(flex flex-wrap gap-1 p-1),
      tag: ~S(p-1.5 text-sm badge badge-primary)
    ],
    none: []
  ]

  @modes ~w(single tags)a

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(
        active_option: -1,
        hide_dropdown: true,
        awaiting_update: true
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

  @doc false
  def styles(), do: @styles

  @impl true
  def update(assigns, socket) do
    validate_assigns!(assigns)
    {clear, assigns} = Map.pop(assigns, :clear)

    socket =
      if clear do
        clear_selection(socket)
      else
        socket
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:active_option, -1)
      |> update(:awaiting_update, fn
        _, %{options: _} -> false
        awaiting_update, _ -> awaiting_update
      end)

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
      |> update(:options, &normalize_options/1)
      |> assign(:text_input_field, String.to_atom("#{socket.assigns.field}_text_input"))
      |> assign_new(:selection, fn
        %{form: form, field: field, options: options, mode: mode, value: nil} ->
          initial_selection(input_value(form, field), options, mode)

        %{options: options, mode: mode, value: value} ->
          initial_selection(value, options, mode)
      end)

    {:ok, socket}
  end

  @impl true
  def handle_event("click", _params, socket) do
    socket =
      if socket.assigns.mode == :single && Enum.any?(socket.assigns.selection) &&
           !socket.assigns.disabled do
        reset(socket)
      else
        socket
      end
      |> assign(hide_dropdown: false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("blur", _params, socket) do
    {:noreply, assign(socket, :hide_dropdown, true)}
  end

  @impl true
  def handle_event("focus", _params, socket) do
    {:noreply, assign(socket, :hide_dropdown, false)}
  end

  @impl true
  def handle_event("keyup", %{"value" => text, "key" => key}, socket)
      when key not in ["ArrowDown", "ArrowUp", "Enter", "Tab", "Escape"] do
    socket =
      if socket.assigns.mode == :single && Enum.any?(socket.assigns.selection) do
        socket
      else
        text = String.trim(text)

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

          assign(socket, hide_dropdown: false, current_text: text, awaiting_update: true)
        else
          assign(socket, options: [], current_text: nil)
        end
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    {:noreply,
     assign(
       socket,
       active_option: next_selectable(socket.assigns),
       hide_dropdown: false
     )}
  end

  @impl true
  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    {:noreply,
     assign(socket,
       active_option: prev_selectable(socket.assigns),
       hide_dropdown: false
     )}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    socket =
      if socket.assigns.mode == :single && Enum.any?(socket.assigns.selection) do
        reset(socket)
      else
        maybe_select(socket)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :hide_dropdown, true)}
  end

  @impl true
  def handle_event("option_click", %{"idx" => idx}, socket) do
    socket = assign(socket, :active_option, String.to_integer(idx))
    {:noreply, maybe_select(socket)}
  end

  @impl true
  def handle_event("option_remove", %{"idx" => idx}, socket) do
    {:noreply, unselect(socket, String.to_integer(idx))}
  end

  @impl true
  def handle_event(_event, _params, socket) do
    {:noreply, socket}
  end

  defp validate_assigns!(assigns) do
    if Map.has_key?(assigns, :style) do
      unless assigns[:style] in Keyword.keys(@styles) do
        raise(
          ~s(Invalid style: #{inspect(assigns.style)}. Style must be one of: #{inspect(Keyword.keys(@styles))})
        )
      end
    end

    if mode = assigns[:mode] do
      unless mode in @modes do
        raise(~s(Invalid mode: "#{assigns.mode}". Mode must be one of: #{inspect(@modes)}))
      end
    end

    if Map.has_key?(assigns, :options) do
      unless Enumerable.impl_for(assigns.options) do
        raise "options must be enumerable"
      end
    end

    valid_assigns = Keyword.keys(@default_opts) ++ [:field, :form, :id, :options, :clear]

    for {assign, _} <- assigns_to_attributes(assigns) do
      unless assign in valid_assigns do
        most_similar =
          (valid_assigns -- [:field, :form, :id, :options])
          |> Enum.sort_by(&String.jaro_distance(to_string(&1), to_string(assign)))
          |> List.last()

        raise ~s(Invalid assign: "#{assign}". Did you mean "#{most_similar}" ?)
      end
    end
  end

  defp maybe_select(%{assigns: %{selection: selection, max_selectable: max_selectable}} = socket)
       when max_selectable > 0 and length(selection) >= max_selectable do
    assign(socket,
      active_option: -1,
      hide_dropdown: true
    )
  end

  defp maybe_select(
         %{
           assigns: %{
             current_text: current_text,
             user_defined_options: true,
             awaiting_update: false,
             active_option: -1
           }
         } = socket
       )
       when is_binary(current_text) do
    {:ok, option} = normalize(current_text)

    if already_selected?(option, socket.assigns.selection) do
      socket
    else
      select(socket, option)
    end
  end

  defp maybe_select(
         %{assigns: %{options: [option], selection: selection, active_option: -1}} = socket
       ) do
    if already_selected?(option, selection) do
      socket
    else
      select(socket, option)
    end
  end

  defp maybe_select(%{assigns: %{active_option: -1}} = socket), do: socket

  defp maybe_select(socket) do
    select(socket, Enum.at(socket.assigns.options, socket.assigns.active_option))
  end

  defp select(socket, selected) do
    selection =
      case socket.assigns.mode do
        :tags ->
          socket.assigns.selection ++ [selected]

        _ ->
          [selected]
      end

    socket
    |> assign(
      active_option: -1,
      selection: selection,
      hide_dropdown: true
    )
    |> push_event("select", %{
      id: socket.assigns.id,
      mode: socket.assigns.mode,
      selection: selection
    })
  end

  defp clear_selection(%{assigns: %{mode: :single}} = socket), do: reset(socket, false)

  defp clear_selection(socket), do: unselect(socket, :all)

  defp unselect(socket, pos) do
    socket =
      if pos == :all do
        assign(socket, :selection, [])
      else
        update(socket, :selection, &List.delete_at(&1, pos))
      end

    push_event(socket, "select", %{
      id: socket.assigns.id,
      mode: socket.assigns.mode,
      selection: socket.assigns.selection
    })
  end

  defp reset(socket, focus \\ true) do
    socket
    |> assign(selection: [])
    |> push_event("reset", %{id: socket.assigns.id, focus: focus})
  end

  defp initial_selection(value, options, :single) do
    if option = Enum.find(options, fn %{value: val} -> value == val end) do
      [option]
    else
      case normalize(value) do
        {:ok, option} -> List.wrap(option)
        :error -> invalid_option(value, :selection)
      end
    end
  end

  defp initial_selection(value, options, _) do
    value
    |> then(&if Enumerable.impl_for(&1), do: &1, else: List.wrap(&1))
    |> Enum.map(
      &if option = Enum.find(options, fn %{value: value} -> value == &1 end) do
        option
      else
        case normalize(&1) do
          {:ok, option} -> option
          :error -> invalid_option(&1, :selection)
        end
      end
    )
  end

  defp normalize_options(options) do
    Enum.map(
      options,
      &case normalize(&1) do
        {:ok, option} -> option
        :error -> invalid_option(&1, :option)
      end
    )
  end

  defp normalize(option_or_selection) do
    case option_or_selection do
      nil ->
        {:ok, nil}

      %{key: key, value: _value} = option ->
        {:ok, Map.put_new(option, :label, key)}

      %{value: value} = option ->
        {:ok, Map.put_new(option, :label, value)}

      option when is_list(option) ->
        Map.new(option)
        |> normalize()

      {label, value} ->
        {:ok, %{label: label, value: value}}

      option when is_binary(option) or is_atom(option) or is_number(option) ->
        {:ok, %{label: option, value: option}}

      _ ->
        :error
    end
  end

  defp invalid_option(option, what) do
    raise """
    invalid #{if what == :selection, do: "element in selection", else: "element in options"}: #{inspect(option)}
    elements of #{what} can be:

    atoms, strings or numbers
    maps or keywords with keys: (:label, :value) or (:key, :value) and an optional key :tag_label
    2-element tuples
    """
  end

  defp values(options) do
    Enum.map(options, &encode(&1.value))
  end

  defp value([%{value: value} | _]), do: encode(value)

  defp value(_), do: nil

  defp label(:single, [%{label: label} | _]), do: label

  defp label(_, _), do: nil

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

  defp encode(value) when is_atom(value) or is_binary(value) or is_number(value), do: value

  defp encode(value), do: Jason.encode!(value)

  defp already_selected?(option, selection) do
    option.label in Enum.map(selection, & &1.label)
  end

  defp next_selectable(%{
         selection: selection,
         active_option: active_option,
         max_selectable: max_selectable
       })
       when max_selectable > 0 and length(selection) >= max_selectable,
       do: active_option

  defp next_selectable(%{options: options, active_option: active_option, selection: selection}) do
    options
    |> Enum.with_index()
    |> Enum.reject(fn {opt, _} -> active_option == opt || already_selected?(opt, selection) end)
    |> Enum.map(fn {_, idx} -> idx end)
    |> Enum.find(active_option, &(&1 > active_option))
  end

  defp prev_selectable(%{
         selection: selection,
         active_option: active_option,
         max_selectable: max_selectable
       })
       when max_selectable > 0 and length(selection) >= max_selectable,
       do: active_option

  defp prev_selectable(%{options: options, active_option: active_option, selection: selection}) do
    options
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.reject(fn {opt, _} -> active_option == opt || already_selected?(opt, selection) end)
    |> Enum.map(fn {_, idx} -> idx end)
    |> Enum.find(active_option, &(&1 < active_option))
  end

  defp x(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 20 20"
      fill="currentColor"
      class="w-5 h-5 @class"
    >
      <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
    </svg>
    """
  end
end
