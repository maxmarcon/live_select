defmodule LiveSelect do
  @moduledoc ~S"""
  Dynamic drop down input for live view

  The `LiveSelect` input is rendered by calling the `render/3` function and passing it a form and the name of the input.
  LiveSelect with create a text input field in which the user can type text. As the text changes, LiveSelect will render a dropdown below the text input
  with the matching options, which the user can then select.

  ## How to control which elements are rendered in the dropdown

  Whenever the user enters or modifies the text in the text input, LiveSelect sends a message with the current text and its component id to the Liveview. The Liveview's job is to handle
  the message and by calling `LiveSelect.update/2`

  ## Example

  Template:
  ```
  <.form for={:my_form} let={f} phx-change="change">
      <%= live_select f, :city_search %> 
  </.form>
  ```

  Liveview:
  ```
  def handle_info("live_select_change", %{text: text} = change_msg) do 
    cities = City.search(text)
    
    LiveSelect.update(change_msg, cities)
    
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
  Update a `LiveSelect` component with new options. `update_request` is the original update request message received from the component,
  and options is the new list of options.
  """
  def update(%{module: module, id: component_id} = _update_request, options)
      when is_list(options),
      do: Phoenix.LiveView.send_update(module, id: component_id, options: options)
end
