defmodule LiveSelect do
  use Phoenix.Component

  alias LiveSelect.Component

  @moduledoc ~S"""
  The `LiveSelect` component is rendered by calling the `live_select/1` function and passing it a form field.
  LiveSelect creates a text input field in which the user can type text, and hidden input field(s) that will contain the value of the selected option(s).
    
  Whenever the user types something in the text input, LiveSelect triggers a `live_select_change` event for your LiveView or LiveComponent.
  The message has a `text` parameter containing the current text entered by the user, as well as `id` and `field` parameters with the id of the 
  LiveSelect component and the name of the LiveSelect form field, respectively.
  Your job is to handle the event, retrieve the list of selectable options and then call `Phoenix.LiveView.send_update/3`
  to send the list of options to LiveSelect. See the "Examples" section below for details, and check out the 
  [cheatsheet](https://hexdocs.pm/live_select/cheatsheet.html) for some useful tips.

  Selection can happen either using the keyboard, by navigating the options with the arrow keys and then pressing enter, or by
  clicking an option with the mouse.

  Whenever an option is selected, `LiveSelect` will trigger a standard `phx-change` event in the form. See the "Examples" section
  below for details on how to handle the event.

  In single mode, if the configuration option `allow_clear` is set, the user can manually clear the selection by clicking on the `x` button on the input field.
  In tags mode, single tags can be removed by clicking on them.

  ## Single mode  

  <img alt="demo" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/demo_single.gif" width="300" />

  ## Tags mode
    
  <img alt="demo" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/demo_tags.gif" width="300" />

  When `:tags` mode is enabled `LiveSelect` allows the user to select multiple entries. The entries will be visible above the text input field as removable tags.

  The selected entries will be passed to your live view's `change` and `submit` event handlers as a list of entries, just like an [HTML <select> element with multiple attribute](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/multiple) would do.

  ## Options

  You can pass or update the list of options the user can choose from with the `options` assign.
  Each option will be assigned a label, which will be shown in the dropdown, and a value, which will be the value of the
  LiveSelect input when the option is selected.

  `options` can be any enumeration of the following elements:

  * _atoms, strings or numbers_: In this case, each element will be both label and value for the option
  * _tuples_: `{label, value}` corresponding to label and value for the option
  * _maps_: `%{label: label, value: value}` or `%{value: value}` 
  * _keywords_: `[label: label, value: value]` or `[value: value]`

  In the case of maps and keywords, if only `value` is specified, it will be used as both value and label for the option.

  Because you can pass a list of tuples, you can use maps and keyword lists to pass the list of options, for example:

  ```
  %{Red: 1, Yellow: 2, Green: 3}
  ```

  Will result in 3 options with labels `:Red`, `:Yellow`, `:Green` and values 1, 2, and 3.

  Note that the option values, if they are not strings, will be JSON-encoded. Your LiveView will receive this JSON-encoded version in the `phx-change` and `phx-submit` events.

  ## Styling 
    
  `LiveSelect` supports 3 styling modes:

  * `tailwind`: uses standard tailwind utility classes (the default)
  * `daisyui`: uses [daisyUI](https://daisyui.com/) classes.
  * `none`: no styling at all.

  Please see [the styling section](styling.md) for details 

  ## Alternative tag labels
    
  Sometimes, in `:tags` mode, you might want to use alternative labels for the tags. For example, you might want the labels in the tags to be shorter 
  in order to save space. You can do this by specifying an additional `tag_label` key when passing options as map or keywords. For example, passing these options:

  ```
  [%{label: "New York", value "NY", tag_label: "NY"}, %{label: "Barcelona", value: "BCN", tag_label: "BCN"}]  
  ```

  will result in "New York" and "Barcelona" being used for the options in the dropdown, while "NY" and "BCN" will be used for the tags (and the values).

  ## Sticky options

  Add  the `sticky: true` flag to an option to prevent it from being removed from the selection:

  ```
  [%{label: "New York", value: "NY", sticky: true}]
  ```

  Now, whenever the selection contains "New York", the option will stick and the user won't be able to remove it.

  ## Slots
    
  You can control how your options and tags are rendered by using the `:option` and `:tag` slots.
  Let's say you want to show some fancy icons next to each option in the dropdown and the tags:

  ```elixir  
  <.live_select
          field={@form[:city_search]}
          phx-target={@myself}
          mode={:tags}
        >
          <:option :let={option}>
            <div class="flex">
              <.globe />&nbsp;<%= option.label %>
            </div>
          </:option>
          <:tag :let={option}>
              <.check />&nbsp;<%= option.label %>
          </:tag>
  </.live_select>
  ```

  Here's the result:
      
  <img alt="slots" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/slots.png" width="200" />

  ## Controlling the selection programmatically

  You can always control the selection programmatically, overriding the current user-selected values,
  by sending a `:value` update to `LiveSelect` via `Phoenix.LiveView.send_update/3`:

  ```
  send_update(LiveSelect.Component, id: live_select_id, value: new_selection)
  ```

  `new_selection` must be a single element in `:single` mode, a list in `:tags` mode. If it's `nil`, the selection will be cleared.  
  After updating the selection, `LiveSelect` will trigger a change event in the form.  

  To set a custom id for the component to use with `Phoenix.LiveView.send_update/3`, you can pass the `id` assign to `live_select/1`.

  ## Examples

  These examples describe all the moving parts in detail. You can see these examples in action, see which messages and events are being sent, and play around
  with the configuration easily with the [showcase app](https://github.com/maxmarcon/live_select#showcase-app).

  ### Single mode

  The user can search for cities.
  The LiveSelect main form input is called `city_search`.
  When a city is selected, the coordinates of that city will be the value of the form input.
  The name of the selected city is available in the text input field named `city_search_text_input`.

  _Template:_
  ```
  <.form for={@form} phx-change="change">
    <.live_select field={@form[:city_search]} /> 
  </.form>
  ```
    
  > #### Forms implemented in LiveComponents {: .warning}
  > 
  > If your form is implemented in a LiveComponent and not in a LiveView, you have to add the `phx-target` attribute
  > when rendering LiveSelect:
  >
  > ```elixir
  >  <.live_select field={@form[:city_search]} phx-target={@myself} />
  > ```  
    
  _LiveView or LiveComponent that is the target of the form's events:_
  ```
  import LiveSelect

  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do 
      cities = City.search(text)
      # cities could be:
      # [ {"city name 1", [lat_1, long_1]}, {"city name 2", [lat_2, long_2]}, ... ]
      #
      # but it could also be (no coordinates in this case):
      # [ "city name 1", "city name 2", ... ]
      #
      # or:
      # [ [label: "city name 1", value: [lat_1, long_1]], [label: "city name 2", value: [lat_2, long_2]], ... ] 
      #
      # or even:
      # ["city name 1": [lat_1, long_1], "city name 2": [lat_2, long_2]]

      send_update(LiveSelect.Component, id: live_select_id, options: cities)
    
      {:noreply, socket}
  end

  @impl true
  def handle_event(
      "change",
      %{"my_form" => %{"city_search_text_input" => city_name, "city_search" => city_coords}},
      socket
    ) do
      IO.puts("You selected city #{city_name} located at: #{city_coords}")

      {:noreply, socket}
  end  
  ```

  ### Tags mode

  Let's say you want to build on the previous example and allow the user to select multiple cities and not only one.
  The `:tags` mode allows you to do exactly this.

  _Template:_
  ```
  <.form for={@form} phx-change="change">
    <.live_select field={@form[:city_search]} mode={:tags} /> 
  </.form>
  ```

  _LiveView or LiveComponent that is the target of the form's events:_
  ```
  @impl true
  def handle_event(
      "change",
      %{"my_form" => %{"city_search" => list_of_coords}},
      socket
    ) do
    # list_of_coords will contain the list of the JSON-encoded coordinates of the selected cities, for example:
    # ["[-46.565,-23.69389]", "[-48.27722,-18.91861]"]    

    IO.puts("You selected cities located at: #{list_of_coords}")

    {:noreply, socket}
  end  
  ```

  ### Multiple LiveSelect inputs in the same LiveView  

  If you have multiple LiveSelect inputs in the same LiveView, you can distinguish them based on the field id. 
  For example:

  _Template:_
  ```
  <.form for={@form} phx-change="change">
    <.live_select field={@form[:city_search]} />
    <.live_select field={@form[:album_search]} />
  </.form>
  ```

  _LiveView or LiveComponent:_
  ```
  @impl true
  def handle_event("live_select_change", %{"text" => text, "id" => live_select_id, "field" => live_select_field}, socket) do
    options =
      case live_select_field do
        "form_name_city_search" -> City.search(text)
        "form_name_album_search" -> Album.search(text)
      end

    send_update(LiveSelect.Component, id: live_select_id, options: options)

    {:noreply, socket}
  end
  ```
  """

  @doc ~S"""
  Renders a `LiveSelect` input in a form.
    
  [INSERT LVATTRDOCS]

  ## Styling attributes

  * See [the styling section](styling.md) for details 
  """
  @doc type: :component

  attr :field, :any,
    required: true,
    doc: "a Phoenix.HTML.FormField struct identifying the form's field"

  attr :id, :string,
    doc:
      ~S(an id to assign to the component. If none is provided, `#{form_name}_#{field}_live_select_component` will be used)

  attr :mode, :atom,
    values: [:single, :tags],
    default: Component.default_opts()[:mode],
    doc: "either `:single` (for single selection), or `:tags` (for multiple selection using tags)"

  attr :options, :list,
    doc:
      ~s(initial available options to select from. See the "Options" section for details on what you can pass here)

  attr :value, :any, doc: "used to manually set a selection - overrides any values from the form. 
  Must be a single element in `:single` mode, or a list of elements in `:tags` mode."

  attr :max_selectable, :integer,
    default: Component.default_opts()[:max_selectable],
    doc: "limits the maximum number of selectable elements. `0` means unlimited"

  attr :user_defined_options, :boolean,
    default: Component.default_opts()[:user_defined_options],
    doc: "if `true`, hitting enter will always add the text entered by the user to the selection"

  attr :allow_clear, :boolean,
    doc:
      ~s(if `true`, when in single mode, display a "x" button in the input field to clear the selection)

  attr :disabled, :boolean, doc: "set this to `true` to disable the input field"

  attr :placeholder, :string, doc: "placeholder text for the input field"

  attr :debounce, :integer,
    default: Component.default_opts()[:debounce],
    doc:
      ~S(number of milliseconds to wait after the last keystroke before triggering a "live_select_change" event)

  attr :update_min_len, :integer,
    default: Component.default_opts()[:update_min_len],
    doc:
      "the minimum length of text in the text input field that will trigger an update of the dropdown."

  attr :style, :atom,
    values: [:tailwind, :daisyui, :none],
    default: Component.default_opts()[:style],
    doc:
      "one of `:tailwind`, `:daisyui` or `:none`. See the [Styling section](styling.html) for details"

  slot(:option,
    doc:
      "optional slot that renders an option in the dropdown. The option's data is available via `:let`"
  )

  slot(:tag, doc: "optional slot that renders a tag. The option's data is available via `:let`")

  attr :"phx-target", :any,
    doc: "Optional target for events. Usually the same target as the form's"

  attr :"phx-blur", :string,
    doc:
      "Event to emit when the text input loses focus. The component id will be sent in the event's params"

  attr :"phx-focus", :string,
    doc:
      "Event to emit when the text input receives focus. The component id will be sent in the event's params"

  @styling_options ~w(active_option_class available_option_class container_class container_extra_class dropdown_class dropdown_extra_class option_class option_extra_class text_input_class text_input_extra_class text_input_selected_class selected_option_class tag_class tag_extra_class tags_container_class tags_container_extra_class)a

  for attr_name <- @styling_options do
    Phoenix.Component.Declarative.__attr__!(
      __MODULE__,
      attr_name,
      :any,
      [doc: false],
      __ENV__.line,
      __ENV__.file
    )
  end

  def live_select(assigns) do
    assigns =
      assigns
      |> update(:field, fn
        %Phoenix.HTML.FormField{} = field, _ ->
          field

        field, %{form: form} ->
          IO.warn(
            "instead of passing separate form and field attributes, pass a single field attribute of type Phoenix.HTML.FormField"
          )

          to_form(form)[field]

        _, _ ->
          raise "if you pass field as atom or string, you also have to pass a form"
      end)
      |> assign_new(:id, fn %{field: field} ->
        "#{field.form.name}_#{field.field}_live_select_component"
      end)
      |> assign(module: LiveSelect.Component)

    ~H"""
    <.live_component {assigns} />
    """
  end
end
