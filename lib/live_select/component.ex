defmodule LiveSelect.Component do
  @moduledoc "The module that implements the `LiveSelect` live component"

  use Phoenix.LiveComponent

  import Phoenix.HTML.Form,
    only: [text_input: 3, hidden_input: 3]

  import LiveSelect.ClassUtil

  @required_assigns ~w(field)a

  @default_opts [
    active_option_class: nil,
    allow_clear: false,
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
    update_min_len: 1,
    value: nil
  ]

  @styles [
    tailwind: [
      active_option: ~W(text-white bg-gray-600),
      available_option: ~W(cursor-pointer hover:bg-gray-400 rounded),
      container: ~W(relative h-full text-black),
      dropdown: ~W(absolute rounded-md shadow z-50 bg-gray-100 w-full),
      option: ~W(rounded px-4 py-1),
      selected_option: ~W(text-gray-400),
      text_input:
        ~W(rounded-md w-full disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400 pr-6),
      text_input_selected: ~W(border-gray-600 text-gray-600),
      tags_container: ~W(flex flex-wrap gap-1 p-1),
      tag: ~W(p-1 text-sm rounded-lg bg-blue-400 flex)
    ],
    daisyui: [
      active_option: ~W(active),
      available_option: ~W(cursor-pointer),
      container: ~W(dropdown dropdown-open),
      dropdown: ~W(dropdown-content menu menu-compact shadow rounded-box bg-base-200 p-1 w-full),
      option: nil,
      selected_option: ~W(disabled),
      text_input: ~W(input input-bordered w-full pr-6),
      text_input_selected: ~W(input-primary),
      tags_container: ~W(flex flex-wrap gap-1 p-1),
      tag: ~W(p-1.5 text-sm badge badge-primary)
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
        awaiting_update: true,
        saved_selection: nil
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
      |> assign_new(:selection, fn
        %{field: field, options: options, mode: mode} ->
          set_selection(field.value, options, mode)
      end)

    socket =
      if Map.has_key?(assigns, :value) do
        update(socket, :selection, fn
          _, %{options: options, mode: mode, value: value} ->
            set_selection(value, options, mode)
        end)
        |> client_select(%{input_event: true})
      else
        socket
      end

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
  def handle_event("focus", _params, socket) do
    socket =
      socket
      |> maybe_save_selection()
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
  def handle_event("options_clear", _params, socket) do
    socket =
      socket
      |> assign(current_text: nil, options: [])

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
    {:noreply, clear(socket, %{input_event: true})}
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
          :clear,
          :hide_dropdown,
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
         %{assigns: %{selection: selection, max_selectable: max_selectable}} = socket,
         _extra_params
       )
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
         } = socket,
         extra_params
       )
       when is_binary(current_text) do
    {:ok, option} = normalize(current_text)

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

  defp maybe_select(socket, extra_params) do
    select(socket, Enum.at(socket.assigns.options, socket.assigns.active_option), extra_params)
  end

  defp select(socket, selected, extra_params) do
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
    |> update(:saved_selection, fn
      _, %{selection: selection, mode: :single} when selection != [] -> selection
      saved_selection, _ -> saved_selection
    end)
  end

  defp maybe_restore_selection(socket) do
    update(socket, :selection, fn
      _, %{saved_selection: saved_selection, mode: :single} when saved_selection != nil ->
        saved_selection

      selection, _ ->
        selection
    end)
    |> assign(:saved_selection, nil)
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
        selection: socket.assigns.selection,
        parent_event: parent_event
      }
      |> Map.merge(extra_params)
    )
  end

  def parent_event(socket, nil, _payload), do: socket

  def parent_event(socket, event, payload) do
    socket
    |> push_event("parent_event", %{
      id: socket.assigns.id,
      event: event,
      payload: payload
    })
  end

  defp set_selection(value, options, :single) do
    if option = Enum.find(options, fn %{value: val} -> value == val end) do
      [option]
    else
      case normalize(value) do
        {:ok, option} -> List.wrap(option)
        :error -> invalid_option(value, :selection)
      end
    end
  end

  defp set_selection(value, options, _) do
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

  defp normalize_options(options) when is_map(options) do
    normalize_options(Enum.sort(options))
  end

  defp normalize_options(options) do
    options
    |> Enum.map(
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
      class={["w-5 h-5", @class]}
    >
      <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
    </svg>
    """
  end
end
