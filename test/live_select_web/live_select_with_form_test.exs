defmodule LiveSelectWeb.LiveSelectWithFormTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase

  test "can be rendered in a form" do
    component =
      render_component(LiveSelect, id: "live_select", form: :my_form)
      |> Floki.parse_document!()

    assert component
           |> Floki.find("input#my_form_live_select[type=hidden]")
           |> Enum.any?()

    assert component
           |> Floki.find("input#my_form_live_select_text_input[type=text]")
           |> Enum.any?()
  end
  
  
end
