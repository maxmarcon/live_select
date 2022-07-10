defmodule LiveSelectWeb.LiveSelect do
  @moduledoc false

  use LiveSelectWeb.ConnCase

  test "can be rendered", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    assert has_element?(live, "input#form_live_select[type=hidden]")

    assert has_element?(live, "input#form_live_select_text_input[type=text]")
  end
end
