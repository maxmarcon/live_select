defmodule LiveSelect.ComponentTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase
  alias LiveSelect.Component

  test "can be rendered" do
    component =
      render_component(Component, id: "live_select", form: :my_form)
      |> Floki.parse_document!()

    assert component
           |> Floki.find("input#my_form_live_select[type=hidden]")
           |> Enum.any?()

    assert component
           |> Floki.find("input#my_form_live_select_text_input[type=text]")
           |> Enum.any?()
  end
end
