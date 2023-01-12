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
        options: ["A", "B", "C"]
      )

    assert_options(component, ["A", "B", "C"])
  end

  describe "in single mode" do
    test "can set initial selection from form" do
      changeset = Ecto.Changeset.change({%{city_search: "B"}, %{city_search: :string}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          form: form,
          field: :city_search,
          options: ["A", "B", "C"]
        )

      assert_selected_static(component, "B")
    end

    test "can set initial selection from form for non-string values" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: %{"x" => 1, "y" => 2}}, %{city_search: :string}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          form: form,
          field: :city_search,
          options: [
            %{label: "A", value: %{}},
            %{label: "B", value: %{"x" => 1, "y" => 2}},
            %{label: "C", value: [1, 2]}
          ]
        )

      assert_selected_static(component, "B", %{"x" => 1, "y" => 2})
    end

    test "can set initial selection from form without options" do
      changeset = Ecto.Changeset.change({%{city_search: "B"}, %{city_search: :string}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          form: form,
          field: :city_search
        )

      assert_selected_static(component, "B")
    end

    test "can set initial selection and label from form without options" do
      changeset = Ecto.Changeset.change({%{city_search: {"B", 1}}, %{city_search: :string}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          form: form,
          field: :city_search
        )

      assert_selected_static(component, "B", 1)
    end
  end

  describe "in tags mode" do
    test "can set initial selection from form" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: ["B", "D"]}, %{city_search: {:array, :string}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          mode: :tags,
          form: form,
          field: :city_search,
          options: ["A", "B", "C", "D"]
        )

      assert_selected_multiple_static(component, ["B", "D"])
    end

    test "can set initial selection from form for non-string values" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: [%{"x" => 1, "y" => 2}, [1, 2]]}, %{city_search: :string}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          mode: :tags,
          form: form,
          field: :city_search,
          options: [
            %{label: "A", value: %{}},
            %{label: "B", value: %{"x" => 1, "y" => 2}},
            %{label: "C", value: [1, 2]}
          ]
        )

      assert_selected_multiple_static(component, [%{"x" => 1, "y" => 2}, [1, 2]], ["B", "C"])
    end

    test "can set initial selection from form without options" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: ["B", "D"]}, %{city_search: {:array, :string}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          mode: :tags,
          form: form,
          field: :city_search
        )

      assert_selected_multiple_static(component, ["B", "D"])
    end

    test "can set initial selection and labels from form without options" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: [{"B", 1}, {"D", 2}]}, %{city_search: {:array, :string}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(LiveSelect.Component,
          id: "live_select",
          mode: :tags,
          form: form,
          field: :city_search
        )

      assert_selected_multiple_static(component, ["1", "2"], ["B", "D"])
    end
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

  test "raises if non-enumerable options are given" do
    assert_raise(
      RuntimeError,
      ~s(options must be enumerable),
      fn ->
        render_component(LiveSelect.Component,
          id: "live_select",
          form: :form,
          field: :input,
          options: "not a list"
        )
      end
    )
  end
end
