defmodule LiveSelect do
  @moduledoc false

  import Phoenix.LiveView.Helpers

  def render(form, name, opts \\ []) do
    assigns = %{module: LiveSelect.Component}

    p =
      [
        id: opts[:id],
        form: form,
        name: name
      ]
      |> Keyword.merge(opts)

    ~H"""
    <.live_component module={@module} {p} />
    """
  end
end
