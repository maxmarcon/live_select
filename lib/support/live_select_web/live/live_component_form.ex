defmodule LiveSelectWeb.LiveComponentForm do
  @moduledoc false

  use LiveSelectWeb, :live_component
  alias LiveSelect.CityFinder

  import LiveSelect
  use PhoenixHTMLHelpers

  @impl true
  def mount(socket) do
    socket = assign(socket, :form, to_form(%{}, as: "my_form"))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="form_component" phx-hook="Foo" phx-target={@myself}>
      <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <.live_select field={@form[:city_search]} mode={:tags} phx-target={@myself}>
          <:option :let={option}>
            with custom slot: <%= option.label %>
          </:option>
          <:tag :let={option}>
            with custom slot: <%= option.label %>
          </:tag>
        </.live_select>
        <.live_select field={@form[:city_search_custom_clear_single]} phx-target={@myself} allow_clear>
          <:clear_button>
            custom clear button
          </:clear_button>
        </.live_select>
        <.live_select
          field={@form[:city_search_custom_clear_tags]}
          phx-target={@myself}
          allow_clear
          mode={:tags}
        >
          <:clear_button>
            custom clear button
          </:clear_button>
        </.live_select>
        <%= submit("Submit", class: "btn btn-primary") %>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("live_select_change", %{"id" => live_select_id, "text" => text}, socket) do
    result =
      GenServer.call(CityFinder, {:find, text})
      |> Enum.map(&value_mapper/1)

    send_update(LiveSelect.Component, id: live_select_id, options: result)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"my_form" => %{"city_search" => _live_select}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change", %{"my_form" => %{"city_search" => _live_select}}, socket) do
    {:noreply, socket}
  end

  defp value_mapper(%{name: name} = value), do: %{label: name, value: Map.from_struct(value)}

  defp value_mapper(value), do: value
end
