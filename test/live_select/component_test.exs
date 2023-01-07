defmodule LiveSelect.ComponentTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true
  alias LiveSelect.Component
  import LiveSelect.TestHelpers

  test "can be rendered" do
    component =
      render_component(Component, id: "live_select", form: :my_form, field: :live_select)
      |> Floki.parse_document!()

    assert component
           |> Floki.find("input#my_form_live_select")
           |> Enum.any?()

    assert component
           |> Floki.find("input#my_form_live_select_text_input")
           |> Enum.any?()
  end

  test "can set initial options" do
    component =
      render_component(LiveSelect.Component,
        id: "live_select",
        form: :form,
        field: :input,
        options: [{"A", 1}, "B", "C"]
      )

    assert_options(component, ["A", "B", "C"])
  end

  test "raises if invalid assign is passed" do
    assert_raise(RuntimeError, ~r(Invalid assign: "invalid_assign"), fn ->
      render_component(Component,
        id: "live_select",
        form: :my_form,
        field: :live_select,
        invalid_assign: "foo"
      )
    end)
  end

  test "raises if _extra_class option is used with styles == :none" do
    assert_raise(
      RuntimeError,
      ~r/when using `style: :none`, please use only `container_class`/i,
      fn ->
        render_component(Component,
          id: "live_select",
          form: :my_form,
          field: :live_select,
          style: :none,
          container_extra_class: "foo"
        )
      end
    )
  end

  test "raises if unknown mode is given" do
    assert_raise(
      RuntimeError,
      ~s(Invalid mode: "not_a_valid_mode". Mode must be one of: [:single, :tags]),
      fn ->
        render_component(LiveSelect.Component,
          id: "live_select",
          form: :form,
          field: :input,
          mode: :not_a_valid_mode
        )
      end
    )
  end

  test "raises if unknown style is given" do
    assert_raise(
      RuntimeError,
      ~s(Invalid style: "not_a_valid_style". Style must be one of: [:tailwind, :daisyui, :none]),
      fn ->
        render_component(LiveSelect.Component,
          id: "live_select",
          form: :form,
          field: :input,
          style: :not_a_valid_style
        )
      end
    )
  end
end
