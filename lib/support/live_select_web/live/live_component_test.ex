defmodule LiveSelectWeb.LiveComponentTest do
  @moduledoc false

  use LiveSelectWeb, :live_view

  alias LiveSelectWeb.LiveComponentForm

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component module={LiveComponentForm} id="lc_form" />
    """
  end
end
