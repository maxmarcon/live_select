defmodule LiveSelect do
  @moduledoc ~S"""
  Dynamic drop down input for live view

  The input is render calling the `live_select/3` function and passing it a form and the name of the input.

  `LiveSelect` works by rendering a dropdown that will be dynamically filled by a handler in the parent LiveView.


  """

  import Phoenix.LiveView.Helpers

  @doc ~S"""
  Renders a `live_select` input in your form.

  * `:form` - the form, either a `Phoenix.HTML.Form` or an atom
  * `:name` - the name of the input field

  Opts:

  * `msg_prefix` - the prefix of messages sent by `LiveSelect` to the parent component. Defaults to "live_select"
  * `search_term_min_length` - minimum number of keystrokes after which the dropdown is populated. Defaults to 3.

  """
  def live_select(form, name, opts \\ []) do
    form_name = if is_struct(form, Phoenix.HTML.Form), do: form.name, else: to_string(form)

    assigns =
      opts
      |> Map.new()
      |> Map.put_new(:id, "#{form_name}_live_select_component")
      |> Map.put(:module, LiveSelect.Component)
      |> Map.put(:name, name)
      |> Map.put(:form, form)

    ~H"""
    <.live_component {assigns} />
    """
  end
end
