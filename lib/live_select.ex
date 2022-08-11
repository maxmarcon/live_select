defmodule LiveSelect do
  @moduledoc ~S"""
  Dynamic dropdown input for live view

  The `LiveSelect` input is rendered by calling the `live_select/3` function and passing it a form and the name of the input.
  LiveSelect creates a text input field in which the user can type text. As the text changes, LiveSelect will render a dropdown below the text input
  containing the matching options, which the user can then select.

  Selection can happen either using the keyboard, by navigating the options with the arrow keys and then pressing enter, or by
  selecting an option by clicking on it with the mouse.

  When an option has been selected, `LiveSelect` will trigger a standard `phx-change` event in the form. See the "Examples" section
  below for details on how to handle the event.

  After an option has been selected, the input field can be reset by clicking on it.

  ![demo](assets/demo.gif)
     
  ## Reacting to user's input

  Whenever the user types something in the text input, LiveSelect sends a message with the following format to the LiveView:

  ```
  {"live_select_change", change_msg}
  ```

  Where change_msg is a `t:LiveSelect.ChangeMsg.t/0` struct with a `text` property containing the current content of the input field, and a `field` property with the name of the input field.
  The LiveView's job is to [handle_info/2](`c:Phoenix.LiveView.handle_info/2`) the message and then call `LiveSelect.update/2`
  to update the dropdown's content with the new set of selectable options. See the "Examples" section below for details.

  ## Styling

  You can use the `style` option in `live_select/3` to control which style will be used by default. Currently supported values are 
  `:daisyui` (default) or `:none` (no styles). LiveSelect can style the following elements:

  1. The outer container of the component
  2. The text field
  3. The text field when an option has been selected
  4. The dropdown with the options
  5. The active option the user navigated to using the arrow keys

  For each of these components there is a `{component}_class` and for some a `{component}_extra_class` option, which can be used
  to either override or extend the default CSS classes for the component

  The following table shows the default styles for each component and the options you can use to adjust its CSS classes.

  |Component|Default daisyUI classes|class override option|class extend option|
  |--|--|--|--|
  |*outer container*|"dropdown"|`container_class`|`container_extra_class`|
  |*text field*|"input input-bordered"|`text_input_class`|`text_input_extra_class`|
  |*text field selected*|"input-primary text-primary"|`text_input_selected_class`| |
  |*dropdown*|"dropdown-content menu menu-compact shadow rounded-box"|`dropdown_class`|`dropdown_extra_class`|
  |*active option*|"active"|`active_option_class`| |

  For example, if you want to show a full-width LiveSelect component with a secondary color for the dropdown background
  and active options with a warning background, you can do this:

  ```
  live_select("my_form", "my_input",
      container_extra_class: "w-full",
      text_input_extra_class: "w-full",
      dropdown_extra_class: "w-full bg-secondary",
      active_option_class: "bg-warning"
    )
  ```

  Result:

  ![](assets/styled.jpg)

  ## Examples

  Here's an example that describes all the moving parts in detail. The user can search for cities.
  The LiveSelect main form input is called `city_search`.
  When a city is selected, the coordinates of that city will be the value of the form input.
  Then name of the selected city is available in the text input field named `city_search_text_input`.
    
  Template:
  ```
  <.form for={:my_form} let={f} phx-change="change">
      <%= live_select f, :city_search %> 
  </.form>
  ```

  LiveView:
  ```
  import LiveSelect

  @impl true
  def handle_info({"live_select_change", change_msg}, socket) do 
    cities = City.search(change_msg.text)
    # cities could be:
    # [ {"city name 1", [lat_1, long_1]}, {"city name 2", [lat_2, long_2]}, ... ]
    #
    # but it could also be (no coordinates in this case):
    # [ "city name 1", "city name 2", ... ]
    #
    # or:
    # [ [key: "city name 1", value: [lat_1, long_1]], [key: "city name 2", value: [lat_2, long_2]], ... ] 

    LiveSelect.update(change_msg, cities)
    
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

  ### Multiple LiveSelect inputs in the same LiveView  
    
  If you have multiple LiveSelect inputs in the same LiveView, you can distinguish them based on the input field. 
  For example:

  Template:
  ```
  <.form for={:my_form} let={f} phx-change="change">
      <%= live_select f, :city_search, change_msg: "city-search" %> 
      <%= live_select f, :album_search, change_msg: "album-search" %>
  </.form>
  ```

  LiveView:
  ```
  @impl true
  def handle_info({"city-search", change_msg}, socket) do
    options =
      case change_msg.field do
        :city_search -> City.search(change_msg.text)
        :album_search -> Album.search(change_msg.text)
      end

    LiveSelect.update(change_msg, options)

    {:noreply, socket}
  end
  ```
  """

  import Phoenix.LiveView.Helpers

  @doc ~S"""
  Renders a `LiveSelect` input in a `form` with a given `field` name.

  LiveSelect renders a hidden input with name `field` which contains the selected option.
  The visible text input field will have the name `#{field}_text_input`.
    
  Opts:

  * `change_msg` - the name of the message sent by `LiveSelect` to the parent component when an update is required (i.e. the first part of the message tuple). Useful for distinguishing among multiple LiveSelect inputs. Defaults to "live_select_change"
  * `disabled` - set this to a truthy value to disable the input field
  * `placeholder` - placeholder text for the input field
  * `search_term_min_length` - the minimum length of text in the search field that will trigger an update of the dropdown. It has to be a positive integer. Defaults to 3.
  * `style` - either `:daisyui` for daisyui styling (default) or `:none` for no styling. See the "Styles" section above.
  * `container_class` -  See the "Styles" section above for this and the following options.
  * `container_extra_class`
  * `text_input_class`
  * `text_input_extra_class`
  * `text_input_selected_class`
  * `dropdown_class`
  * `dropdown_extra_class`
  * `active_option_class`
    
  """
  def live_select(form, field, opts \\ [])
      when (is_binary(field) or is_atom(field)) and is_list(opts) do
    form_name = if is_struct(form, Phoenix.HTML.Form), do: form.name, else: to_string(form)

    assigns =
      opts
      |> Map.new()
      |> Map.put(:id, "#{form_name}_#{field}_component")
      |> Map.put(:module, LiveSelect.Component)
      # Ecto forms expect atom fields:
      # https://github.com/phoenixframework/phoenix_ecto/blob/master/lib/phoenix_ecto/html.ex#L123
      |> Map.put(:field, String.to_atom("#{field}"))
      |> Map.put(:form, form)

    ~H"""
    <.live_component {assigns} />
    """
  end

  @doc ~S"""
  Updates a `LiveSelect` component with new options. `change_msg` must be the message originally sent by the component (i.e the second part of the message tuple),
  and `options` is the new list of options that will be used to fill the dropdown.

  The set of accepted `options` values are the same as for `Phoenix.HTML.Form.select/4`, with the exception that optgroups are not supported yet.
  """
  def update(%{module: module, id: component_id} = _change_msg, options)
      when is_list(options),
      do: Phoenix.LiveView.send_update(module, id: component_id, options: options)
end
