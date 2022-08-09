defmodule LiveSelect do
  @moduledoc ~S"""
  Dynamic dropdown input for live view

  The `LiveSelect` input is rendered by calling the `live_select/3` function and passing it a form and the name of the input.
  LiveSelect with create a text input field in which the user can type text. As the text changes, LiveSelect will render a dropdown below the text input
  with the matching options, which the user can then select.

  ## Update the content of the dropdown

  Whenever the user types something in the text input, LiveSelect sends a message with the current text and its component id to the LiveView. 
  The LiveView's job is to [handle_info/2](`c:Phoenix.LiveView.handle_info/2`) the message and then call `LiveSelect.update/2`
  to update the dropdown's content. See the "Example" section below.

  ## Styles

  You can use the `style` option in `live_select/3` to control which style will be used. Currently supported values are 
  `:daisyui` (default) or `:none`. LiveSelect styles the following elements:

  1. The outer container of the component
  2. The text field
  3. The text field when an option has been selected
  4. The dropdown with the options
  5. The active option the user navigated to using the arrow keys

  For each of these components there is a `{component}_class` and for some a `{component}_extra_class` option, which can be used
  to either override or extend the default CSS classes for the component

  The following table shows the default styles for each component and the options you can use to adjust its CSS classes.

  |Component|Default daisyUI class|class override option|class extend option|
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

  ## Example

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
    // cities:
    // {"city name 1", [lat_1, long_1]} ... {"city name 2", [lat_2, long_2]}
    
    LiveSelect.update(change_msg, cities)
    
    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"my_form" => %{"city_search" => city_coords}}, socket) do 
    IO.puts("You selected a city located at: #{city_coords}")
    
    {:noreply, socket}
  end
  ```

  If you have multiple LiveSelect elements, you can assign them custom ids to distinguish between them:

  Template:
  ```
  <.form for={:my_form} let={f} phx-change="change">
      <%= live_select f, :city_search, id: "city-search" %> 
      <%= live_select f, :album_search, id: "album-search" %>
  </.form>
  ```

  LiveView:
  ```
  def handle_info({"live_select_change", change_msg}, socket) do 
    options = case chang_msg.id do
      "city-search" -> City.search(change_msg.text)
      "album-search" -> Album.search(change_msg.text)
    end
   
    LiveSelect.update(change_msg, options)
    
    {:noreply, socket}
  end
  ```
  """

  import Phoenix.LiveView.Helpers

  @doc ~S"""
  Renders a `LiveSelect` input in a `form` with a given `field` name.

  Opts:

  * `msg_prefix` - the prefix of messages sent by `LiveSelect` to the parent component. Defaults to "live_select"
  * `search_term_min_length` - the minimum length of text in the search field that will trigger an update of the dropdown. It has to be a positive integer. Defaults to 3.
  * `id` - assign a specific id to the component. Useful when you have multiple LiveSelect components in the same view. Defaults to: "form_name_field_name_component"
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
      |> Map.put_new(:id, "#{form_name}_#{field}_component")
      |> Map.put(:module, LiveSelect.Component)
      |> Map.put(:field, field)
      |> Map.put(:form, form)

    ~H"""
    <.live_component {assigns} />
    """
  end

  @doc ~S"""
  Update a `LiveSelect` component with new options. `update_request` must be the original update request message received from the component,
  and options is the new list of options that will be used to fill the dropdown.
  """
  def update(%{module: module, id: component_id} = _update_request, options)
      when is_list(options),
      do: Phoenix.LiveView.send_update(module, id: component_id, options: options)
end
