defmodule LiveSelect do
  @moduledoc false

  import Phoenix.LiveView.Helpers

  def render(form, name, opts \\ []) do
    form_name = if is_struct(form, Phoenix.HTML.Form), do: form.name, else: to_string(form)

    assigns =
      opts
      |> Map.new()
      |> Map.put_new(:id, "#{form_name}_#{name}")
      |> Map.put(:module, LiveSelect.Component)
      |> Map.put(:name, name)
      |> Map.put(:form, form)

    ~H"""
    <.live_component {assigns} />
    """
  end
end
