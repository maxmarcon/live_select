defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

  import LiveSelect

  defmodule Settings do
    use Ecto.Schema

    import Ecto.Changeset

    @empty_styles [
      active_option_class: nil,
      container_class: nil,
      container_extra_class: nil,
      dropdown_class: nil,
      dropdown_extra_class: nil,
      text_input_class: nil,
      text_input_extra_class: nil,
      text_input_selected_class: nil
    ]

    @primary_key false
    embedded_schema do
      field(:active_option_class, :string)
      field(:container_class, :string)
      field(:container_extra_class, :string)
      field(:debounce, :integer, default: 100)
      field(:dropdown_class, :string)
      field(:dropdown_extra_class, :string)
      field(:form_name, :string, default: "my_form")
      field(:field_name, :string, default: "city_search")
      field(:placeholder, :string, default: "Search for a city")
      field(:search_delay, :integer, default: 10)
      field(:search_term_min_length, :integer)
      field(:style, Ecto.Enum, values: [:daisyui, :none])
      field(:text_input_class, :string)
      field(:text_input_extra_class, :string)
      field(:text_input_selected_class, :string)
      field(:new, :boolean, default: true)
      field(:disabled, :boolean)
    end

    def changeset(source \\ %__MODULE__{}, params, opts \\ []) do
      opts = Keyword.validate!(opts, skip_validation: false)

      source
      |> cast(params, [
        :active_option_class,
        :container_class,
        :container_extra_class,
        :debounce,
        :dropdown_class,
        :dropdown_extra_class,
        :field_name,
        :form_name,
        :placeholder,
        :search_delay,
        :search_term_min_length,
        :style,
        :text_input_class,
        :text_input_extra_class,
        :text_input_selected_class,
        :disabled
      ])
      |> maybe_validate(opts[:skip_validation])
      |> put_change(:new, false)
    end

    def live_select_opts(%__MODULE__{} = settings) do
      settings
      |> Map.drop([:search_delay, :form_name, :field_name, :new])
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

    defp maybe_validate(changeset, true), do: changeset

    defp maybe_validate(changeset, false) do
      changeset
      |> validate_required([:field_name, :form_name])
      |> validate_number(:debounce, greater_than_or_equal_to: 0)
      |> validate_number(:search_delay, greater_than_or_equal_to: 0)
      |> validate_number(:search_term_min_length, greater_than: 0)
      |> maybe_apply_initial_styles()
      |> validate_styles()
    end

    defp validate_styles(changeset) do
      if get_field(changeset, :style) == :none do
        changeset
      else
        for {class, extra_class} <- [
              {:container_class, :container_extra_class},
              {:dropdown_class, :dropdown_extra_class},
              {:text_input_class, :text_input_extra_class}
            ],
            reduce: changeset do
          changeset ->
            if get_field(changeset, class) && get_field(changeset, extra_class) do
              errmsgs = "You can only specify one of these"

              changeset
              |> add_error(class, errmsgs)
              |> add_error(extra_class, errmsgs)
            else
              changeset
            end
        end
      end
    end

    defp maybe_apply_initial_styles(changeset) do
      style_changed = get_change(changeset, :style)
      new_settings = get_field(changeset, :new)

      if style_changed || new_settings do
        initial_classes =
          Application.get_env(:live_select, :initial_classes, [])
          |> Keyword.get(style_changed || LiveSelect.Component.default_opts()[:style], [])

        @empty_styles
        |> Keyword.merge(initial_classes)
        |> Enum.reduce(changeset, fn {class, initial_value}, changeset ->
          if (style_changed && !new_settings) || !get_change(changeset, class) do
            put_change(changeset, class, initial_value)
          else
            changeset
          end
        end)
      else
        changeset
      end
    end
  end

  @max_events 3
  @class_file "priv/static/assets/class.txt"

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
        new_event: false,
        selected: "",
        selected_text: "",
        submitted: false,
        save_classes_pid: nil,
        show_styles: false
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
        |> assign(:show_styles, false)
      else
        socket
      end

    settings =
      get_in(socket.assigns, [Access.key(:changeset), Access.key(:data)]) ||
        %Settings{}

    changeset =
      Settings.changeset(
        settings,
        params,
        skip_validation: !!params["skip_validation"]
      )

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, settings} ->
        socket =
          socket
          |> spawn_save_classes_task(settings)
          |> assign(:changeset, Ecto.Changeset.change(settings))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:changeset, changeset)

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

  @impl true
  def handle_event(event, params, socket) do
    Process.send_after(self(), :clear_new_event, 1_000)

    socket =
      case event do
        "change" ->
          form_name = socket.assigns.changeset.data.form_name
          field_name = socket.assigns.changeset.data.field_name

          selected = get_in(params, [form_name, field_name])

          selected_text = get_in(params, [form_name, field_name <> "_text_input"])

          assign(socket, selected: selected, selected_text: selected_text, submitted: false)

        "submit" ->
          assign(socket, submitted: true)

        _ ->
          socket
      end

    {:noreply,
     assign(socket,
       events:
         [%{params: params, event: event} | socket.assigns.events] |> Enum.take(@max_events),
       new_event: true
     )}
  end

  @impl true
  def handle_info(:clear_new_event, socket) do
    {:noreply, assign(socket, :new_event, false)}
  end

  def handle_info({:update_live_select, change_msg, options}, socket) do
    update_options(change_msg, options)

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    Process.send_after(self(), :clear_new_event, 1_000)

    message_handler().handle(message, delay: socket.assigns.changeset.data.search_delay)

    {:noreply,
     assign(socket,
       events: [%{msg: message} | socket.assigns.events] |> Enum.take(@max_events),
       new_event: true
     )}
  end

  defp default_value_descr(field) do
    if default = LiveSelect.Component.default_opts()[field] do
      "default: #{default}"
    else
      ""
    end
  end

  def default_class(style, class) do
    if default = LiveSelect.Component.default_class(style, class) do
      "default: #{default}"
    else
      ""
    end
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
    |> Map.take([
      :active_option_class,
      :container_class,
      :container_extra_class,
      :dropdown_class,
      :dropdown_extra_class,
      :text_input_class,
      :text_input_extra_class,
      :text_input_selected_class
    ])
    |> Enum.reject(fn {_key, classes} -> is_nil(classes) end)
    |> Enum.map(fn {_key, classes} -> classes <> "\n" end)
    |> Enum.into(File.stream!(@class_file))
  end

  defp message_handler() do
    Application.get_env(:live_select, :message_handler) ||
      raise "you need to specify a :message_handler in your :live_select config"
  end

  defp valid_class(changeset, class) do
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
end
