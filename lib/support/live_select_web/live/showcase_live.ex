defmodule LiveSelectWeb.ShowcaseLive do
  use LiveSelectWeb, :live_view

  import LiveSelect
  alias LiveSelect.{Component, City}

  use PhoenixHTMLHelpers

  defmodule CitySearchMany do
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      embeds_many(:city_search, City, on_replace: :delete)
    end

    def changeset(schema \\ %__MODULE__{}, params) do
      cast(schema, params, [])
      |> cast_embed(:city_search)
    end
  end

  defmodule CitySearchSingle do
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      embeds_one(:city_search, City, on_replace: :update)
    end

    def changeset(schema \\ %__MODULE__{}, params) do
      cast(schema, params, [])
      |> cast_embed(:city_search)
    end
  end

  defmodule Settings do
    use Ecto.Schema

    import Ecto.Changeset

    @class_options [
      :active_option_class,
      :available_option_class,
      :clear_button_class,
      :clear_button_extra_class,
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
      field(:allow_clear, :boolean)
      field(:debounce, :integer, default: Component.default_opts()[:debounce])
      field(:disabled, :boolean)
      field(:max_selectable, :integer, default: Component.default_opts()[:max_selectable])
      field(:user_defined_options, :boolean)
      field(:mode, Ecto.Enum, values: [:single, :tags], default: Component.default_opts()[:mode])
      field(:new, :boolean, default: true)
      field(:placeholder, :string, default: "Search for a city")
      field(:search_delay, :integer, default: 10)
      field(:style, Ecto.Enum, values: [:daisyui, :tailwind, :none], default: :tailwind)
      field(:update_min_len, :integer, default: 3)
      field(:options, {:array, :string}, default: [])
      field(:selection, {:array, :string}, default: [])
      field(:"phx-blur", :string)
      field(:"phx-focus", :string)

      for class <- @class_options do
        field(class, :string)
      end
    end

    def changeset(source \\ %__MODULE__{}, params) do
      source
      |> cast(
        params,
        [
          :allow_clear,
          :debounce,
          :disabled,
          :max_selectable,
          :user_defined_options,
          :mode,
          :options,
          :selection,
          :placeholder,
          :search_delay,
          :style,
          :update_min_len,
          :"phx-focus",
          :"phx-blur"
        ] ++ @class_options
      )
      |> validate_required([:search_delay])
      |> validate_number(:debounce, greater_than_or_equal_to: 0)
      |> validate_number(:search_delay, greater_than_or_equal_to: 0)
      |> validate_number(:update_min_len, greater_than_or_equal_to: 0)
      |> maybe_apply_initial_styles()
      |> validate_styles()
      |> put_change(:new, false)
    end

    def live_select_opts(%__MODULE__{} = settings, remove_defaults \\ false) do
      default_opts = Component.default_opts()

      settings
      |> Map.drop([:search_delay, :new, :selection])
      |> Map.from_struct()
      |> then(
        &if is_nil(&1.style) do
          Map.delete(&1, :style)
        else
          &1
        end
      )
      |> Map.reject(fn {option, value} ->
        (remove_defaults && value == Keyword.get(default_opts, option)) ||
          (settings.mode == :single && option == :max_selectable) ||
          (settings.mode != :single && option == :allow_clear)
      end)
      |> Keyword.new()
    end

    def has_style_errors?(%Ecto.Changeset{errors: errors}) do
      errors
      |> Keyword.take(@class_options)
      |> Enum.any?()
    end

    def has_style_options?(changeset) do
      Enum.any?(@class_options, &Ecto.Changeset.get_field(changeset, &1))
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
          |> Keyword.get(Component.default_opts()[:style], [])

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

  defmodule Render do
    @moduledoc false

    use Phoenix.Component

    def event(assigns) do
      cond do
        assigns[:event] ->
          ~H"""
          <p>
            handle_event( <span class="text-success"><%= inspect(@event) %></span>, <span class="text-info"><%= inspect(
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

      format_value = fn
        value when is_binary(value) -> inspect(value)
        value -> "{#{inspect(value)}}"
      end

      assigns = assign(assigns, opts: opts, format_value: format_value)

      ~H"""
      <div>
        <span class="text-success">&lt;.live_select</span>
        <br />&nbsp;&nbsp; <span class="text-success">field</span>=<span class="text-info">{my_form[:city_search]}</span>
        <%= for {key, value} <- @opts, !is_nil(value) do %>
          <%= if value == true do %>
            <br />&nbsp;&nbsp; <span class="text-success"><%= key %></span>
          <% else %>
            <br />&nbsp;&nbsp; <span class="text-success"><%= key %></span>=<span class="text-info"><%= @format_value.(value) %></span>
          <% end %>
        <% end %>
        <span class="text-success">/&gt;</span>
      </div>
      """
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        live_select_form: to_form(CitySearchSingle.changeset(%{}), as: "my_form"),
        schema_module: CitySearchSingle,
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
    socket =
      if params["reset"] do
        socket
        |> assign(:events, [])
      else
        socket
      end

    changeset =
      Settings.changeset(params)
      |> then(
        &if params["placeholder"] == "" do
          Ecto.Changeset.put_change(&1, :placeholder, nil)
        else
          &1
        end
      )

    case Ecto.Changeset.apply_action(changeset, :create) do
      {:ok, settings} ->
        socket.assigns

        socket =
          socket
          |> assign(:settings_form, Settings.changeset(settings, %{}) |> to_form)
          |> update(:schema_module, fn _, %{settings_form: settings_form} ->
            if settings_form[:mode].value == :single, do: CitySearchSingle, else: CitySearchMany
          end)

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> assign(:settings_form, to_form(changeset))
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
        %{"settings" => params, "_target" => target},
        socket
      ) do
    params =
      params
      |> Enum.reject(fn {k, v} -> v == "" && k != "placeholder" end)
      |> Map.new()

    socket =
      if target == ~w(settings mode) do
        assign(
          socket,
          :schema_module,
          if(params["mode"] == "single", do: CitySearchSingle, else: CitySearchMany)
        )
        |> update(:live_select_form, fn _, %{schema_module: schema_module} ->
          to_form(schema_module.changeset(%{}), as: "my_form")
        end)
      else
        socket
      end

    socket = push_patch(socket, to: ~p(/?#{params}))

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

  def handle_event("clear-selection", _params, socket) do
    send_update(Component,
      id: "my_form_city_search_live_select_component",
      value: nil
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(event, params, socket) do
    socket =
      case event do
        "live_select_change" ->
          change_event_handler().handle(params,
            delay: socket.assigns.settings_form.data.search_delay
          )

          socket

        event when event in ~w(change submit) ->
          params =
            update_in(params, ~w(my_form city_search), fn
              nil -> %{}
              "" -> nil
              selection when is_list(selection) -> Enum.map(selection, &decode/1)
              selection -> decode(selection)
            end)

          changeset = socket.assigns.schema_module.changeset(params["my_form"])

          socket =
            assign(
              socket,
              :live_select_form,
              to_form(changeset, as: "my_form")
            )

          if event == "submit" do
            selection =
              Ecto.Changeset.apply_changes(changeset).city_search
              |> then(fn
                city_search when is_list(city_search) ->
                  Enum.map(city_search, &Map.from_struct(&1))

                nil ->
                  nil

                city_search ->
                  Map.from_struct(city_search)
              end)
              |> then(fn
                [] -> nil
                selection -> selection
              end)

            assign(socket,
              cities: selection && Jason.encode!(selection),
              submitted: true
            )
          else
            socket
          end

        _event ->
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

  def handle_info({:update_live_select, %{"id" => id}, options}, socket) do
    options =
      options
      |> Enum.sort()
      |> Enum.map(&value_mapper/1)

    send_update(Component, id: id, options: options)

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
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

  defp value_mapper(%{name: name} = value), do: %{label: name, value: Map.from_struct(value)}

  defp value_mapper(value), do: value

  defp decode(value) do
    case Jason.decode(value) do
      {:ok, value} -> value
      {:error, _} -> value
    end
  end

  defp live_select_assigns(changeset) do
    Settings.live_select_opts(changeset.data)
    |> Keyword.update(:disabled, !changeset.valid?, fn
      true -> true
      _ -> !changeset.valid?
    end)
  end

  defp default_value_descr(field) do
    if default = Component.default_opts()[field] do
      "default: #{default}"
    else
      ""
    end
  end

  defp default_class(style, class) do
    case Component.default_class(style, class) do
      nil -> nil
      list -> Enum.join(list, " ")
    end
  end

  defp change_event_handler() do
    Application.get_env(:live_select, :change_event_handler) ||
      raise "you need to specify a :change_event_handler in your :live_select config"
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
