defmodule LiveSelectWeb.LiveComponentForm do
  @moduledoc false

  use LiveSelectWeb, :live_component
  alias LiveSelect.CityFinder

  import LiveSelect
  import Phoenix.HTML.Form

  @impl true
  def mount(socket) do
    socket = assign(socket, :form, to_form(%{}, as: "my_form_new_style"))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="form_component" phx-hook="Foo" phx-target={@myself}>
      <div>
        New form style
        <a
          class="link"
          target="_blank"
          href="https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1-examples-inside-liveview"
        >
          (form created with to_form/2 and stored as assign)
        </a>
      </div>
      <.form for={@form} phx-submit="submit" phx-target={@myself}>
        <.live_select form={@form} field={:city_search} mode={:tags} phx-target={@myself}>
          <:option :let={option}>
            with custom slot: <%= option.label %>
          </:option>
          <:tag :let={option}>
            with custom slot: <%= option.label %>
          </:tag>
        </.live_select>
        <%= submit("Submit", class: "btn btn-primary") %>
      </.form>

      <div>
        Old form style
        <a
          class="link"
          target="_blank"
          href="https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#form/1-using-the-for-attribute"
        >
          (form created in .form component, captured with :let)
        </a>
      </div>
      <.form :let={f} for={%{}} as={:my_form_old_style} phx-submit="submit" phx-target={@myself}>
        <.live_select form={f} field={:city_search} />
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
  def handle_event("submit", %{"my_form_old_style" => %{"city_search" => _live_select}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"my_form_new_style" => %{"city_search" => _live_select}}, socket) do
    {:noreply, socket}
  end
end
