defmodule LiveSelectWeb.LiveSelectWithFormTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase

  test "can be rendered in a form", %{conn: conn} do
    {:ok, view, html} = live(conn, "/?form=my_form")

    assert view
           |> has_element?("input#my_form_live_select[type=hidden]")

    assert view
           |> has_element?("input#my_form_live_select_text_input[type=text]")
  end
end
