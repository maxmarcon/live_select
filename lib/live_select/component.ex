defmodule LiveSelect.Component do
  @moduledoc false

  alias LiveSelect.ChangeMsg

  use Phoenix.LiveComponent
  import Phoenix.HTML.Form, except: [reset: 1, label: 2]
  import LiveSelect.ClassUtil

  @default_opts [
    active_option_class: nil,
    container_class: nil,
    container_extra_class: nil,
    debounce: 100,
    default_value: nil,
    disabled: false,
    dropdown_class: nil,
    dropdown_extra_class: nil,
    mode: :single,
    option_class: nil,
    option_extra_class: nil,
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
    update_min_len: 3
  ]

  @styles [
    tailwind: [
      active_option: ~S(text-white bg-gray-600),
      container: ~S(relative h-full text-black),
      dropdown: ~S(absolute rounded-xl shadow z-50 bg-gray-100 w-full cursor-pointer),
      option: ~S(rounded-lg px-4 py-1 hover:bg-gray-400),
      selected_option: ~S(text-gray-400),
      text_input:
        ~S(rounded-md w-full disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400),
      text_input_selected: ~S(border-gray-600 text-gray-600),
      tags_container: ~S(flex flex-wrap gap-1 p-1),
      tag: ~S(p-1 text-sm rounded-lg bg-blue-400 flex)
    ],
    daisyui: [
      active_option: ~S(active),
      container: ~S(dropdown dropdown-open),
      dropdown:
        ~S(dropdown-content menu menu-compact shadow rounded-box bg-base-200 p-1 w-full cursor-pointer),
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
        disabled: false,
        options: [],
        hide_dropdown: true
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
      |> update(:options, &normalize_options/1)
      |> assign_new(:selection, fn %{form: form, field: field, options: options} ->
        form_value = input_value(form, field)

        options
        |> Enum.filter(fn %{value: value} ->
          (is_list(form_value) && value in form_value) ||
            value == form_value
        end)
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
      |> assign(:text_input_field, String.to_atom("#{socket.assigns.field}_text_input"))

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

          assign(socket, hide_dropdown: false)
        else
          assign(socket, :options, [])
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
        select(socket, socket.assigns.active_option)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :hide_dropdown, true)}
  end

  @impl true
  def handle_event("option_click", %{"idx" => idx}, socket) do
    {:noreply, select(socket, String.to_integer(idx))}
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
    if style = assigns[:style] do
      unless style in Keyword.keys(@styles) do
        raise(
          ~s(Invalid style: "#{assigns.style}". Style must be one of: #{inspect(Keyword.keys(@styles))})
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

    valid_assigns = Keyword.keys(@default_opts) ++ [:field, :form, :id, :options]

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

  defp select(socket, -1), do: socket

  defp select(socket, selected_position) do
    selected = Enum.at(socket.assigns.options, selected_position)

    selection =
      case socket.assigns.mode do
        :tags -> socket.assigns.selection ++ [selected]
        _ -> [selected]
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

  defp unselect(socket, pos) do
    socket = update(socket, :selection, &List.delete_at(&1, pos))

    push_event(socket, "select", %{
      id: socket.assigns.id,
      mode: socket.assigns.mode,
      selection: socket.assigns.selection
    })
  end

  defp reset(socket) do
    socket
    |> assign(selection: [])
    |> push_event("reset", %{id: socket.assigns.id})
  end

  defp normalize_options(options) do
    options
    |> Enum.map(fn
      %{value: value} = option ->
        Map.put_new(option, :label, value)

      option when is_list(option) ->
        Map.new(option)
        |> Map.put_new(:label, option[:key] || option[:value])

      {label, value} ->
        %{label: label, value: value}

      option when is_binary(option) or is_atom(option) or is_number(option) ->
        %{label: option, value: option}

      option ->
        raise """
        invalid option: #{inspect(option)}
        options must enumerate to:

        a list of atom, strings or numbers
        a list of maps or keywords with keys: (:label, :value) or (:key, :value) and an optional key :tag_value
        a list of tuples
        """
    end)
  end

  defp values(options) do
    Enum.map(options, &encode(&1.value))
  end

  defp value([], default_value), do: encode(default_value)

  defp value([%{value: value} | _], _default_value), do: encode(value)

  defp label(:single, [%{label: label}]), do: label

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

  defp next_selectable(%{options: options, active_option: active_option, selection: selection}) do
    options
    |> Enum.with_index()
    |> Enum.reject(fn {opt, _} -> active_option == opt || opt in selection end)
    |> Enum.map(fn {_, idx} -> idx end)
    |> Enum.find(active_option, &(&1 > active_option))
  end

  defp prev_selectable(%{options: options, active_option: active_option, selection: selection}) do
    options
    |> Enum.with_index()
    |> Enum.reverse()
    |> Enum.reject(fn {opt, _} -> active_option == opt || opt in selection end)
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
