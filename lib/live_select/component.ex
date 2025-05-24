defmodule LiveSelect.Component do
  @moduledoc "The module that implements the `LiveSelect` live component"

  use Phoenix.LiveComponent

  import PhoenixHTMLHelpers.Form,
    only: [text_input: 3, hidden_input: 3]

  import LiveSelect.ClassUtil

  @required_assigns ~w(field)a

  @default_opts [
    active_option_class: nil,
    allow_clear: false,
    available_option_class: nil,
    unavailable_option_class: nil,
    clear_button_class: nil,
    clear_button_extra_class: nil,
    clear_tag_button_class: nil,
    clear_tag_button_extra_class: nil,
    current_text: nil,
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
    update_min_len: 1,
    value: nil
  ]

  @styles [
    tailwind: [
      active_option: ~W(text-white bg-gray-600),
      available_option: ~W(cursor-pointer hover:bg-gray-400 rounded),
      unavailable_option: ~W(text-gray-400),
      clear_button: ~W(hidden cursor-pointer),
      clear_tag_button: ~W(cursor-pointer),
      container: ~W(h-full text-black relative),
      dropdown: ~W(absolute rounded-md shadow z-50 bg-gray-100 inset-x-0 top-full),
      option: ~W(rounded px-4 py-1),
      selected_option: ~W(cursor-pointer font-bold hover:bg-gray-400 rounded),
      text_input:
        ~W(rounded-md w-full disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400 pr-6),
      text_input_selected: ~W(border-gray-600 text-gray-600),
      tags_container: ~W(flex flex-wrap gap-1 p-1),
      tag: ~W(p-1 text-sm rounded-lg bg-blue-400 flex)
    ],
    daisyui: [
      active_option: ~W(active menu-active),
      available_option: ~W(cursor-pointer),
      unavailable_option: ~W(disabled),
      clear_button: ~W(hidden cursor-pointer),
      clear_tag_button: ~W(cursor-pointer),
      container: ~W(dropdown dropdown-open),
      dropdown:
        ~W(dropdown-content z-[1] menu menu-compact shadow rounded-box bg-base-200 p-1 w-full),
      option: nil,
      selected_option: ~W(cursor-pointer font-bold),
      text_input: ~W(input input-bordered w-full pr-6),
      text_input_selected: ~W(input-primary),
      tags_container: ~W(flex flex-wrap gap-1 p-1),
      tag: ~W(p-1.5 text-sm badge badge-primary)
    ],
    none: []
  ]

  @modes ~w(single tags quick_tags)a

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(
        active_option: -1,
        hide_dropdown: true,
        awaiting_update: true,
        last_selection: nil,
        selection: [],
        value_mapper: & &1
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

    assigns =
      if Map.has_key?(socket.assigns, :field) && Map.has_key?(assigns, :field) do
        # this is a rerender: do not reset options
        Map.delete(assigns, :options)
      else
        assigns
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:active_option, -1)
      |> update(:awaiting_update, fn
        _, %{options: _} -> false
        awaiting_update, _ -> awaiting_update
      end)

    for required <- @required_assigns do
      unless socket.assigns[required] do
        raise ~s/Missing required assign "#{required}"/
      end
    end

    socket =
      @default_opts
      |> Enum.reduce(socket, fn {opt, default}, socket ->
        socket
        |> assign_new(opt, fn -> default end)
      end)
      |> update(:options, &normalize_options/1)
      |> assign(:text_input_field, String.to_atom("#{socket.assigns.field.field}_text_input"))

    socket =
      if field = assigns[:field] do
        update(
          socket,
          :selection,
          fn selection, %{options: options, mode: mode, value_mapper: value_mapper} ->
            update_selection(
              field.value,
              selection,
              options,
              mode,
              value_mapper
            )
          end
        )
      else
        socket
      end

    socket =
      if Map.has_key?(assigns, :value) do
        update(socket, :selection, fn
          selection, %{options: options, value: value, mode: mode, value_mapper: value_mapper} ->
            update_selection(value, selection, options, mode, value_mapper)
        end)
        |> client_select(%{input_event: true})
      else
        socket
      end

    socket = maybe_save_selection(socket)

    {:ok, socket}
  end

  @impl true
  def handle_event("blur", _params, socket) do
    socket =
      maybe_restore_selection(socket)
      |> assign(:hide_dropdown, true)
      |> client_select(%{parent_event: socket.assigns[:"phx-blur"]})

    {:noreply, socket}
  end

  @impl true
  def handle_event(event, _params, socket) when event in ~w(focus click) do
    socket =
      socket
      |> then(
        &if &1.assigns.mode == :single do
          clear(&1, %{input_event: false, parent_event: &1.assigns[:"phx-focus"]})
        else
          parent_event(&1, &1.assigns[:"phx-focus"], %{id: &1.assigns.id})
        end
      )
      |> assign(hide_dropdown: false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"text" => text}, socket) do
    socket =
      socket
      |> assign(hide_dropdown: false, current_text: text, awaiting_update: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("selection_recovery", selection_from_client, socket) do
    # selection recovery. If we are here, it means that the view has crashed
    # The values have been sent to the form by LV selection recovery and are now in the selection assigns
    # However, the label have been lost because selection recovery only sends the values.
    # Therefore, the component sends this event with the selection stored on the client, which contains the labels
    # Using this selection, we can restore the options and augment the current selection with the labels

    options =
      for %{"label" => label, "value" => value} <- selection_from_client do
        %{label: label, value: value}
      end

    json = Phoenix.json_library()

    {:noreply,
     assign(socket,
       options: options,
       selection:
         Enum.map(socket.assigns.selection, fn %{value: value} ->
           Enum.find(options, fn %{value: option_value} ->
             json.encode!(option_value) == json.encode!(value)
           end)
         end)
         |> Enum.filter(& &1)
     )}
  end

  @impl true
  def handle_event("options_clear", _params, socket) do
    socket =
      socket
      |> assign(current_text: nil, options: [])

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "ArrowDown"}, socket) do
    active_option = next_selectable(socket.assigns)

    socket =
      assign(socket,
        active_option: active_option,
        hide_dropdown: false
      )
      |> push_event("active", %{id: socket.assigns.id, idx: active_option})

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "ArrowUp"}, socket) do
    active_option = prev_selectable(socket.assigns)

    socket =
      assign(socket,
        active_option: active_option,
        hide_dropdown: false
      )
      |> push_event("active", %{id: socket.assigns.id, idx: active_option})

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    {:noreply, maybe_select(socket)}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    socket =
      socket
      |> maybe_restore_selection
      |> assign(:hide_dropdown, true)
      |> client_select(%{})

    {:noreply, socket}
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
  def handle_event("clear", _params, socket) do
    socket =
      socket
      |> assign(last_selection: nil)
      |> clear(%{input_event: true})

    {:noreply, socket}
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

    if Map.has_key?(assigns, :mode) do
      unless assigns.mode in @modes do
        raise(~s(Invalid mode: "#{assigns.mode}". Mode must be one of: #{inspect(@modes)}))
      end
    end

    if Map.has_key?(assigns, :update_min_len) do
      if !is_integer(assigns.update_min_len) || assigns.update_min_len < 0 do
        raise(
          ~s(Invalid update_min_len: "#{assigns.update_min_len}". It must be an non-negative integer)
        )
      end
    end

    if Map.has_key?(assigns, :options) do
      unless Enumerable.impl_for(assigns.options) do
        raise "options must be enumerable"
      end
    end

    valid_assigns =
      Keyword.keys(@default_opts) ++
        @required_assigns ++
        [
          :id,
          :options,
          :"phx-target",
          :"phx-blur",
          :"phx-focus",
          :option,
          :tag,
          :clear_button,
          :hide_dropdown,
          :value_mapper,
          # for backwards compatibility
          :form
        ]

    for {assign, _} <- assigns_to_attributes(assigns) do
      unless assign in valid_assigns do
        most_similar =
          valid_assigns
          |> Enum.sort_by(&String.jaro_distance(to_string(&1), to_string(assign)))
          |> List.last()

        raise ~s(Invalid assign: "#{assign}". Did you mean "#{most_similar}" ?)
      end
    end
  end

  defp maybe_select(socket, extra_params \\ %{})

  defp maybe_select(
         %{
           assigns: %{
             current_text: current_text,
             user_defined_options: true,
             awaiting_update: false,
             active_option: -1
           }
         } = socket,
         extra_params
       )
       when is_binary(current_text) do
    {:ok, option} = normalize_option(current_text)

    if already_selected?(option, socket.assigns.selection) do
      socket
    else
      select(socket, option, extra_params)
    end
  end

  defp maybe_select(
         %{assigns: %{options: [option], selection: selection, active_option: -1}} = socket,
         extra_params
       ) do
    if already_selected?(option, selection) do
      socket
    else
      select(socket, option, extra_params)
    end
  end

  defp maybe_select(%{assigns: %{active_option: -1}} = socket, _extra_params), do: socket

  defp maybe_select(
         %{assigns: %{active_option: active_option, options: options, selection: selection}} =
           socket,
         extra_params
       )
       when active_option >= 0 do
    option = Enum.at(options, active_option)

    if already_selected?(option, selection) do
      pos = get_selection_index(option, selection)
      unselect(socket, pos)
    else
      select(socket, option, extra_params)
    end
  end

  defp maybe_select(socket, extra_params) do
    select(socket, Enum.at(socket.assigns.options, socket.assigns.active_option), extra_params)
  end

  defp get_selection_index(option, selection) do
    Enum.find_index(selection, fn %{label: label} -> label == option.label end)
  end

  defp select(
         socket,
         %{disabled: true} = _selected,
         _extra_params
       ) do
    socket
  end

  defp select(
         %{assigns: %{selection: selection, max_selectable: max_selectable}} = socket,
         _selected,
         _extra_params
       )
       when max_selectable > 0 and length(selection) >= max_selectable do
    socket
  end

  defp select(socket, selected, extra_params) do
    selection =
      if socket.assigns.mode in [:tags, :quick_tags] do
        socket.assigns.selection ++ [selected]
      else
        [selected]
      end

    socket
    |> assign(
      active_option: if(quick_tags_mode?(socket), do: socket.assigns.active_option, else: -1),
      selection: selection,
      hide_dropdown: not quick_tags_mode?(socket)
    )
    |> maybe_save_selection()
    |> client_select(Map.merge(%{input_event: true}, extra_params))
  end

  defp unselect(socket, pos) do
    socket =
      if pos == :all do
        assign(socket, :selection, [])
      else
        update(socket, :selection, &List.delete_at(&1, pos))
      end

    client_select(socket, %{input_event: true})
  end

  defp maybe_save_selection(socket) do
    socket
    |> update(:last_selection, fn
      _, %{selection: selection, mode: :single} when selection != [] -> selection
      last_selection, _ -> last_selection
    end)
  end

  defp maybe_restore_selection(socket) do
    update(socket, :selection, fn
      _, %{last_selection: last_selection, mode: :single} when last_selection != nil ->
        last_selection

      selection, _ ->
        selection
    end)
  end

  defp clear(socket, params) do
    socket
    |> assign(selection: [])
    |> client_select(params)
  end

  defp client_select(socket, extra_params) do
    parent_event = if socket.assigns.mode == :single, do: socket.assigns[:"phx-blur"]

    socket
    |> push_event(
      "select",
      %{
        id: socket.assigns.id,
        mode: socket.assigns.mode,
        current_text: socket.assigns.current_text,
        selection: socket.assigns.selection,
        parent_event: parent_event
      }
      |> Map.merge(extra_params)
    )
  end

  defp parent_event(socket, nil, _payload), do: socket

  defp parent_event(socket, event, payload) do
    socket
    |> push_event("parent_event", %{
      id: socket.assigns.id,
      event: event,
      payload: payload
    })
  end

  defp update_selection(nil, _current_selection, _options, _mode, _value_mapper), do: []

  defp update_selection(value, current_selection, options, :single, value_mapper) do
    List.wrap(normalize_selection_value(value, options ++ current_selection, value_mapper))
  end

  defp update_selection(value, current_selection, options, _mode, value_mapper) do
    value = if Enumerable.impl_for(value), do: value, else: [value]

    Enum.map(value, &normalize_selection_value(&1, options ++ current_selection, value_mapper))
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_selection_value(%Ecto.Changeset{action: :replace}, _options, _value_mapper),
    do: nil

  defp normalize_selection_value(%Ecto.Changeset{} = changeset, options, value_mapper) do
    changeset
    |> Ecto.Changeset.apply_changes()
    |> normalize_selection_value(options, value_mapper)
  end

  defp normalize_selection_value(selection_value, options, value_mapper) do
    selection_value = value_mapper.(selection_value)

    if option = Enum.find(options, fn %{value: value} -> selection_value == value end) do
      option
    else
      case normalize_option(selection_value) do
        {:ok, option} -> option
        :error -> %{label: "", value: selection_value}
      end
    end
  end

  defp normalize_options(options) when is_map(options) do
    normalize_options(Enum.sort(options))
  end

  defp normalize_options(options) do
    options
    |> Enum.map(
      &case normalize_option(&1) do
        {:ok, option} -> option
        :error -> invalid_option(&1)
      end
    )
  end

  defp normalize_option(option) when is_list(option) do
    if Keyword.keyword?(option) do
      Map.new(option)
      |> normalize_option()
    else
      :error
    end
  end

  defp normalize_option(option) when is_map(option) do
    case option do
      %{key: key, value: _value} = option ->
        {:ok, Enum.into(option, %{label: key, disabled: false})}

      %{value: value} = option ->
        {:ok, Enum.into(option, %{label: value, disabled: false})}

      _ ->
        :error
    end
  end

  defp normalize_option(option) when is_tuple(option) do
    case option do
      {label, value} ->
        {:ok, %{label: label, value: value, disabled: false}}

      {label, value, disabled} ->
        {:ok, %{label: label, value: value, disabled: disabled}}

      _ ->
        :error
    end
  end

  defp normalize_option(option) do
    case option do
      nil ->
        {:ok, nil}

      "" ->
        {:ok, nil}

      option when is_binary(option) or is_atom(option) or is_number(option) ->
        {:ok, %{label: option, value: option, disabled: false}}

      _ ->
        :error
    end
  end

  defp invalid_option(option) do
    raise """
    invalid element in options: #{inspect(option)}
    elements can be:

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
    get_in(@styles, [style, element]) |> List.wrap()
  end

  defp class(_style, _element, class_override, nil) when is_list(class_override) do
    class_override
  end

  defp class(_style, _element, class_override, nil) do
    String.split(class_override)
  end

  defp class(:none, element, nil, _class_extend) do
    raise """
    When using `style: :none`, please use only `#{element}_class` and not `#{element}_extra_class`
    """
  end

  defp class(style, element, nil, class_extend) when is_list(class_extend) do
    extend(
      get_in(@styles, [style, element]) |> List.wrap(),
      class_extend
    )
  end

  defp class(style, element, nil, class_extend) do
    class(style, element, nil, String.split(class_extend))
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

  defp encode(value), do: Phoenix.json_library().encode!(value)

  defp already_selected?(option, selection) do
    Enum.any?(selection, fn item -> item.label == option.label end)
  end

  defp quick_tags_mode?(socket) do
    socket.assigns.mode == :quick_tags
  end

  defp next_selectable(%{
         selection: selection,
         active_option: active_option,
         max_selectable: max_selectable,
         mode: mode
       })
       when mode != :quick_tags and max_selectable > 0 and length(selection) >= max_selectable,
       do: active_option

  defp next_selectable(%{
         options: options,
         active_option: active_option,
         selection: selection,
         mode: mode
       }) do
    options
    |> Enum.with_index()
    |> Enum.reject(fn {opt, _} ->
      active_option == opt || (mode != :quick_tags && already_selected?(opt, selection)) ||
        Map.get(opt, :disabled)
    end)
    |> Enum.map(fn {_, idx} -> idx end)
    |> Enum.find(active_option, &(&1 > active_option))
  end

  defp prev_selectable(%{
         selection: selection,
         active_option: active_option,
         max_selectable: max_selectable,
         mode: mode
       })
       when mode != :quick_tags and max_selectable > 0 and length(selection) >= max_selectable,
       do: active_option

  defp prev_selectable(%{
         options: options,
         active_option: active_option,
         selection: selection,
         mode: mode
       }) do
    options
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.reject(fn {opt, _} ->
      active_option == opt || (mode != :quick_tags && already_selected?(opt, selection)) ||
        Map.get(opt, :disabled)
    end)
    |> Enum.map(fn {_, idx} -> idx end)
    |> Enum.find(active_option, &(&1 < active_option || active_option == -1))
  end

  defp x(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 20 20"
      fill="currentColor"
      class={["w-5 h-5"]}
    >
      <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
    </svg>
    """
  end
end
