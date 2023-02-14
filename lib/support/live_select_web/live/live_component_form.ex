defmodule LiveSelectWeb.LiveComponentForm do
  @moduledoc false

  use LiveSelectWeb, :live_component
  alias LiveSelect.CityFinder

  import LiveSelect
  import Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} for={%{}} as={:my_form} phx-submit="submit" phx-target={@myself}>
        <.live_select form={f} field={:city_search} id="live_select" />
        <%= submit("Submit", class: "btn btn-primary") %>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("live_select_change", %{"id" => live_select_id, "text" => text}, socket) do
    result = GenServer.call(CityFinder, {:find, text})

    send_update(LiveSelect.Component, id: live_select_id, options: result)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"live_select" => _live_select}, socket) do
    {:noreply, socket}
  end
end
