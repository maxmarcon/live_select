defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

  import LiveSelect
  alias Phoenix.LiveView.JS

  defmodule Settings do
    use Ecto.Schema

    import Ecto.Changeset

    @class_options [
      :active_option_class,
      :container_class,
      :container_extra_class,
      :dropdown_class,
      :dropdown_extra_class,
      :option_class,
      :option_extra_class,
      :selected_option_class,
      :tag_class,
      :tag_extra_class,
      :tags_container_class,
      :tags_container_extra_class,
      :text_input_class,
      :text_input_extra_class,
      :text_input_selected_class
    ]

    @primary_key false
    embedded_schema do
      field(:debounce, :integer, default: 100)
      field(:disabled, :boolean)
      field(:field_name, :string, default: "city_search")
      field(:form_name, :string, default: "my_form")
      field(:max_selectable, :integer, default: 0)
      field(:mode, Ecto.Enum, values: [:single, :tags], default: :single)
      field(:new, :boolean, default: true)
      field(:placeholder, :string, default: "Search for a city")
      field(:search_delay, :integer, default: 10)
      field(:style, Ecto.Enum, values: [:daisyui, :tailwind, :none], default: :tailwind)
      field(:update_min_len, :integer)
      field(:options, {:array, :string}, default: [])
      field(:selection, {:array, :string}, default: [])

      for class <- @class_options do
        field(class, :string)
      end
    end

    def changeset(source \\ %__MODULE__{}, params) do
      source
      |> cast(
        params,
        [
          :debounce,
          :disabled,
          :field_name,
          :form_name,
          :max_selectable,
          :mode,
          :options,
          :selection,
          :placeholder,
          :search_delay,
          :style,
          :update_min_len
        ] ++ @class_options
      )
      |> validate_required([:field_name, :form_name])
      |> validate_number(:debounce, greater_than_or_equal_to: 0)
      |> validate_number(:search_delay, greater_than_or_equal_to: 0)
      |> validate_number(:update_min_len, greater_than: 0)
      |> maybe_apply_initial_styles()
      |> validate_styles()
      |> put_change(:new, false)
    end

    def live_select_opts(%__MODULE__{} = settings) do
      settings
      |> Map.drop([:search_delay, :form_name, :field_name, :new, :selection])
      |> Map.from_struct()
      |> then(
        &if is_nil(&1.style) do
          Map.delete(&1, :style)
        else
          &1
        end
      )
      |> Keyword.new()
    end

    def has_style_errors?(%Ecto.Changeset{errors: errors}) do
      errors
      |> Keyword.take(@class_options)
      |> Enum.any?()
    end

    def class_options(), do: @class_options

    defp validate_styles(changeset) do
      for {class, extra_class} <- [
            {:container_class, :container_extra_class},
            {:dropdown_class, :dropdown_extra_class},
            {:text_input_class, :text_input_extra_class},
            {:option_class, :option_extra_class},
            {:tags_container_class, :tags_container_extra_class},
            {:tag_class, :tag_extra_class}
          ],
          reduce: changeset do
        changeset ->
          cond do
            get_field(changeset, :style) == :none && get_field(changeset, extra_class) ->
              add_error(changeset, extra_class, "Can't specify this when style is none")

            get_field(changeset, :style) != :none && get_field(changeset, class) &&
                get_field(changeset, extra_class) ->
              errmsgs = "You can only specify one of these"

              changeset
              |> add_error(class, errmsgs)
              |> add_error(extra_class, errmsgs)

            true ->
              changeset
          end
      end
    end

    defp maybe_apply_initial_styles(changeset) do
      new_settings = get_field(changeset, :new)

      if new_settings do
        initial_classes =
          Application.get_env(:live_select, :initial_classes, [])
          |> Keyword.get(LiveSelect.Component.default_opts()[:style], [])

        initial_classes
        |> Enum.reduce(changeset, fn {class, initial_value}, changeset ->
          put_change(changeset, class, initial_value)
        end)
      else
        changeset
      end
    end
  end

  @max_events 3
  @class_file "priv/static/class.txt"

  defmodule Render do
    @moduledoc false

    use Phoenix.Component

    def event(assigns) do
      cond do
        assigns[:event] ->
          ~H"""
          <p>
            def handle_event( <span class="text-success"><%= inspect(@event) %></span>, <span class="text-info"><%= inspect(
            @params
          ) %></span>,
            socket
            )
          </p>
          """

        assigns[:msg] ->
          ~H"""
          <p>
            def handle_info( <span class="text-success"><%= inspect(@msg) %></span>,
            socket
            )
          </p>
          """
      end
    end

    def live_select(assigns) do
      opts =
        assigns[:opts]
        |> Enum.reject(fn {_key, value} -> is_nil(value) end)

      assigns = assign(assigns, :opts, opts)

      ~H"""
      <div>
        <span class="text-success">live_select</span>(<span class="font-bold"><%= @form_name %></span>, <span class="font-bold"><%= @field_name %></span>,
        <%= for {{key, value}, idx} <- Enum.with_index(@opts), !is_nil(value) do %>
          <br />&nbsp;&nbsp; <span class="text-success"><%= key %></span>:
          <span class="text-info">
            <%= inspect(value) <> if idx < length(@opts) - 1, do: ",", else: "" %>
          </span>
        <% end %>
        <br />)
      </div>
      """
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        events: [],
        next_event_id: 0,
        locations: nil,
        submitted: false,
        save_classes_pid: nil,
        show_styles: false,
        class_options: Settings.class_options(),
        style_filter: "",
        dark_mode: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    maybe_terminate_save_classes_task(socket)

    params =
      params
      |> Map.new(fn {k, v} -> if v == "", do: {k, nil}, else: {k, v} end)

    socket =
      if params["reset"] do
        socket
        |> assign(:changeset, nil)
        |> assign(:events, [])
      else
        socket
      end

    settings =
      get_in(socket.assigns, [Access.key(:changeset), Access.key(:data)]) ||
        %Settings{}

    changeset =
      Settings.changeset(
        settings,
        params
      )

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, settings} ->
        socket =
          socket
          |> spawn_save_classes_task(settings)
          |> assign(:form_changeset, make_form_changeset(settings))
          |> assign(:changeset, Ecto.Changeset.change(settings))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)
          |> assign(:form_changeset, Ecto.Changeset.change({%{foo: 1}, %{foo: :integer}}, %{}))
          |> assign(
            :show_styles,
            socket.assigns.show_styles || Settings.has_style_errors?(changeset)
          )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "update-settings",
        %{"settings" => params},
        socket
      ) do
    socket =
      socket
      |> push_patch(to: Routes.live_path(socket, __MODULE__, params))

    {:noreply, socket}
  end

  def handle_event(
        "toggle-styles",
        %{"settings" => %{"show_styles" => show_styles}},
        socket
      ) do
    {:noreply, assign(socket, :show_styles, show_styles == "true")}
  end

  def handle_event("dark-mode", value, socket) do
    {:noreply, assign(socket, :dark_mode, value)}
  end

  def handle_event("filter-styles", %{"settings" => %{"style_filter" => filter}}, socket) do
    {:noreply, assign(socket, style_filter: filter)}
  end

  def handle_event("clear-style-filter", _params, socket) do
    {:noreply, assign(socket, style_filter: "")}
  end

  @impl true
  def handle_event(event, params, socket) do
    socket =
      case event do
        "submit" ->
          form_name = socket.assigns.changeset.data.form_name
          field_name = socket.assigns.changeset.data.field_name
          mode = socket.assigns.changeset.data.mode

          selected = get_in(params, [form_name, field_name])
          selected_text = get_in(params, [form_name, field_name <> "_text_input"])

          {cities, locations} =
            cond do
              mode == :single && selected != "" && selected_text != "" ->
                {"city #{selected_text}", selected}

              mode == :tags && selected ->
                {"#{Enum.count(selected)} #{if Enum.count(selected) > 1, do: "cities", else: "city"}",
                 Enum.join(selected, ", ")}

              true ->
                {nil, nil}
            end

          assign(socket,
            cities: cities,
            locations: locations,
            submitted: true
          )

        _ ->
          socket
      end

    socket =
      socket
      |> update(:next_event_id, &(&1 + 1))
      |> assign(
        events:
          [
            %{params: params, event: event, id: socket.assigns.next_event_id}
            | socket.assigns.events
          ]
          |> Enum.take(@max_events)
      )

    {:noreply, socket}
  end

  def handle_info({:update_live_select, change_msg, options}, socket) do
    update_options(change_msg, options)

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    message_handler().handle(message, delay: socket.assigns.changeset.data.search_delay)

    socket =
      socket
      |> update(:next_event_id, &(&1 + 1))
      |> assign(
        events:
          [%{msg: message, id: socket.assigns.next_event_id} | socket.assigns.events]
          |> Enum.take(@max_events)
      )

    {:noreply, socket}
  end

  defp default_value_descr(field) do
    if default = LiveSelect.Component.default_opts()[field] do
      "default: #{default}"
    else
      ""
    end
  end

  defp default_class(style, class), do: LiveSelect.Component.default_class(style, class)

  defp make_form_changeset(settings) do
    {Map.new([
       {String.to_atom(settings.field_name),
        if(settings.mode == :single, do: List.first(settings.selection), else: settings.selection)}
     ]),
     Map.new([
       {String.to_atom(settings.field_name),
        if(settings.mode == :single, do: :string, else: {:array, :string})}
     ])}
    |> Ecto.Changeset.change(%{})
  end

  defp spawn_save_classes_task(socket, %Settings{} = settings) do
    if connected?(socket) do
      {:ok, pid} =
        Task.Supervisor.start_child(LiveSelectWeb.TaskSupervisor, fn ->
          save_classes(settings)
        end)

      assign(socket, :save_classes_pid, pid)
    else
      socket
    end
  end

  defp maybe_terminate_save_classes_task(socket) do
    if pid = socket.assigns.save_classes_pid do
      Task.Supervisor.terminate_child(
        LiveSelectWeb.TaskSupervisor,
        pid
      )
    end
  end

  defp save_classes(%Settings{} = settings) do
    settings
    |> Map.take(Settings.class_options())
    |> Enum.reject(fn {_key, classes} -> is_nil(classes) end)
    |> Enum.map(fn {_key, classes} -> classes <> "\n" end)
    |> Enum.into(File.stream!(@class_file))
  end

  defp message_handler() do
    Application.get_env(:live_select, :message_handler) ||
      raise "you need to specify a :message_handler in your :live_select config"
  end

  defp valid_class(changeset, class) do
    changeset.errors[class] ||
      Ecto.Changeset.get_field(changeset, :style) != :none ||
      !String.contains?(to_string(class), "extra")
  end

  defp copy_to_clipboard_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-6 h-6"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a.75.75 0 01-.75.75H9a.75.75 0 01-.75-.75v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184"
      />
    </svg>
    """
  end

  defp x_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-6 h-6"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
    </svg>
    """
  end
end
