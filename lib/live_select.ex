defmodule LiveSelect do
  @moduledoc ~S"""
  Dynamic drop down input for live view

  The `LiveSelect` input is rendered by calling the `render/3` function and passing it a form and the name of the input.
  LiveSelect with create a text input field in which the user can type text. As the text changes, LiveSelect will render a dropdown below the text input
  with the matching options, which the user can then select.

  ## How to update the content of the dropdown

  Whenever the user types something in the text input, LiveSelect sends a message with the current text and its component id to the LiveView. 
  The LiveView's job is to handle the message by calling `LiveSelect.update/2`

  ## Example

  Template:
  ```
  <.form for={:my_form} let={f} phx-change="change">
      <%= LiveSelect.render f, :city_search %> 
  </.form>
  ```

  LiveView:
  ```
  def handle_info({"live_select_change", change_msg}, socket) do 
    cities = City.search(change_msg.text)
    
    LiveSelect.update(change_msg, cities)
    
    {:noreply, socket}
  end
  ```

  If you have multiple LiveSelect elements, you can assign them custom ids to distinguish between them:

  Template:
  ```
  <.form for={:my_form} let={f} phx-change="change">
      <%= LiveSelect.render f, :city_search, id: "city-search" %> 
      <%= LiveSelect.render f, :album_search, id: "album-search" %>
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
  * `style` - either `:daisyui` for daisyui styling (default) or `:none` for no styling
    
  """
  def render(form, field, opts \\ [])
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
