defmodule LiveSelectTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase

  test "can be rendered", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    assert has_element?(live, "input#my_form_live_select[type=hidden]")

    assert has_element?(live, "input#my_form_live_select_text_input[type=text]")
  end

  test "can be rendered with a given field name", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?field_name=city_search")

    assert has_element?(live, "input#my_form_city_search[type=hidden]")

    assert has_element?(live, "input#my_form_city_search_text_input[type=text]")
  end

  test "can be rendered with a given form name", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?form_name=special_form")

    assert has_element?(live, "input#special_form_live_select[type=hidden]")

    assert has_element?(live, "input#special_form_live_select_text_input[type=text]")
  end

  test "with at least 3 keystrokes in the input field it does show the dropdown", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_click()

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "B", "value" => "B"})

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "e", "value" => "Be"})

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "r", "value" => "Ber"})

    assert_dropdown_has_size(live, 4)
  end

  test "number of minimum keystrokes can be configured", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?search_term_min_length=4")

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_click()

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "B", "value" => "B"})

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "e", "value" => "Be"})

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "r", "value" => "Ber"})

    assert_dropdown_has_size(live, 0)

    element(live, "input#my_form_live_select_text_input[type=text]")
    |> render_keyup(%{"key" => "l", "value" => "Berl"})

    assert_dropdown_has_size(live, 2)
  end

  defp assert_dropdown_has_size(live_view, size) do
    render(live_view)

    assert render(live_view)
           |> Floki.parse_document!()
           |> Floki.find("ul[name=live-select-dropdown] li")
           |> Enum.count() == size
  end
end
