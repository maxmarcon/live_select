defmodule LiveSelect.ComponentTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true
  alias LiveSelect.Component

  test "can be rendered" do
    component =
      render_component(Component, id: "live_select", form: :my_form, field: :live_select)
      |> Floki.parse_document!()

    assert component
           |> Floki.find("input#my_form_live_select[type=hidden]")
           |> Enum.any?()

    assert component
           |> Floki.find("input#my_form_live_select_text_input[type=text]")
           |> Enum.any?()
  end

  test "raises if invalid option is passed" do
    assert_raise(RuntimeError, ~r(Invalid option: "invalid_option"), fn ->
      render_component(Component,
        id: "live_select",
        form: :my_form,
        field: :live_select,
        invalid_option: "foo"
      )
    end)
  end
end
