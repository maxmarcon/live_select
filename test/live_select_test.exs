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
    Mox.stub_with(LiveSelect.ChangeHandlerMock, LiveSelect.ChangeHandler)

    {:ok, live, _html} = live(conn, "/?form_name=special_form")

    assert has_element?(live, "input#special_form_live_select[type=hidden]")

    assert has_element?(live, "input#special_form_live_select_text_input[type=text]")
  end

  test "with less than 3 keystrokes in the input field it does not show the dropdown", %{
    conn: conn
  } do
    Mox.stub_with(LiveSelect.ChangeHandlerMock, LiveSelect.ChangeHandler)

    {:ok, live, _html} = live(conn, "/")

    type(live, "Be")

    assert_dropdown_has_size(live, 0)
  end

  test "with at least 3 keystrokes in the input field it does show the dropdown", %{conn: conn} do
    Mox.stub_with(LiveSelect.ChangeHandlerMock, LiveSelect.ChangeHandler)

    {:ok, live, _html} = live(conn, "/")

    type(live, "Ber")

    assert_dropdown_has_size(live, &(&1 > 0))
  end

  test "number of minimum keystrokes can be configured", %{conn: conn} do
    Mox.stub_with(LiveSelect.ChangeHandlerMock, LiveSelect.ChangeHandler)

    {:ok, live, _html} = live(conn, "/?search_term_min_length=4")

    type(live, "Ber")

    assert_dropdown_has_size(live, 0)

    type(live, "Berl")

    assert_dropdown_has_size(live, &(&1 > 0))
  end

  test "supports dropdown filled with tuples", %{conn: conn} do
    Mox.stub(LiveSelect.ChangeHandlerMock, :handle_change, fn _ ->
      [{"A", 1}, {"B", 2}, {"C", 3}]
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_dropdown_has_elements(live, ["A", "B", "C"])
  end

  test "supports dropdown filled strings", %{conn: conn} do
    Mox.stub(LiveSelect.ChangeHandlerMock, :handle_change, fn _ ->
      ["A", "B", "C"]
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_dropdown_has_elements(live, ["A", "B", "C"])
  end

  test "supports dropdown filled atoms", %{conn: conn} do
    Mox.stub(LiveSelect.ChangeHandlerMock, :handle_change, fn _ ->
      [:A, :B, :C]
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_dropdown_has_elements(live, ["A", "B", "C"])
  end

  test "supports dropdown filled integers", %{conn: conn} do
    Mox.stub(LiveSelect.ChangeHandlerMock, :handle_change, fn _ ->
      [1, 2, 3]
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_dropdown_has_elements(live, [1, 2, 3])
  end

  test "supports dropdown filled with keywords", %{conn: conn} do
    Mox.stub(LiveSelect.ChangeHandlerMock, :handle_change, fn _ ->
      [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_dropdown_has_elements(live, ["A", "B", "C"])
  end

  defp assert_dropdown_has_size(live, size) when is_integer(size) do
    assert_dropdown_has_size(live, &(&1 == size))
  end

  defp assert_dropdown_has_size(live, fun) when is_function(fun, 1) do
    render(live)

    assert render(live)
           |> Floki.parse_document!()
           |> Floki.find("ul[name=live-select-dropdown] li")
           |> Enum.count()
           |> then(&fun.(&1))
  end

  defp type(live, text) do
    0..String.length(text)
    |> Enum.each(fn pos ->
      element(live, "input#my_form_live_select_text_input[type=text]")
      |> render_keyup(%{"key" => String.at(text, pos), "value" => String.slice(text, 0..pos)})
    end)
  end

  defp assert_dropdown_has_elements(live, elements) do
    assert render(live)
           |> Floki.parse_document!()
           |> Floki.find("ul[name=live-select-dropdown] > li > span")
           |> Floki.text()
           |> String.replace(~r/\s+/, "") ==
             Enum.join(elements)
  end
end
