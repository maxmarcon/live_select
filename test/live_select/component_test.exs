defmodule LiveSelect.ComponentTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true
  import LiveSelect.TestHelpers

  test "can be rendered" do
    component =
      render_component(&LiveSelect.live_select/1,
        form: :my_form,
        field: :live_select
      )
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
      render_component(&LiveSelect.live_select/1,
        form: :form,
        field: :input,
        options: ["A", "B", "C"],
        hide_dropdown: false
      )

    assert_options(component, ["A", "B", "C"])
  end

  test "can be rendered with a custom id" do
    component =
      render_component(&LiveSelect.live_select/1,
        id: "live_select_custom_id",
        form: :form,
        field: :input
      )

    assert length(Floki.find(component, "#live_select_custom_id")) == 1
  end

  describe "in single mode" do
    test "can set initial selection from form" do
      changeset = Ecto.Changeset.change({%{city_search: "B"}, %{city_search: :string}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          form: form,
          field: :city_search,
          options: ["A", "B", "C"]
        )

      assert_selected_static(component, "B")
    end

    test "can set initial selection from form for non-string values" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: %{"x" => 1, "y" => 2}}, %{city_search: :map}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
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
        render_component(&LiveSelect.live_select/1,
          form: form,
          field: :city_search
        )

      assert_selected_static(component, "B")
    end

    test "can set initial selection and label from form without options" do
      changeset = Ecto.Changeset.change({%{city_search: {"B", 1}}, %{city_search: :integer}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          form: form,
          field: :city_search
        )

      assert_selected_static(component, "B", 1)
    end

    test "can set initial selection from form even if it can't be found in the options" do
      changeset = Ecto.Changeset.change({%{city_search: "A"}, %{city_search: :string}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          form: form,
          field: :city_search,
          options: ["B"]
        )

      assert_selected_static(component, "A")
    end

    test "can set initial selection explicitly, bypassing the form" do
      changeset = Ecto.Changeset.change({%{city_search: "B"}, %{city_search: :string}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          form: form,
          field: :city_search,
          value: "D",
          options: ["A", "B", "C"]
        )

      assert_selected_static(component, "D")
    end

    test "raises if initial selection is in the wrong format" do
      changeset =
        Ecto.Changeset.change({%{city_search: [{"B", 1}]}, %{city_search: :integer}}, %{})

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      assert_raise RuntimeError, ~r/invalid element in selection/, fn ->
        render_component(&LiveSelect.live_select/1,
          form: form,
          field: :city_search
        )
      end
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
        render_component(&LiveSelect.live_select/1,
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
          {%{city_search: [%{"x" => 1, "y" => 2}, [1, 2]]}, %{city_search: {:array, :map}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          form: form,
          field: :city_search,
          options: [
            %{label: "A", value: %{}},
            %{label: "B", value: %{"x" => 1, "y" => 2}},
            %{label: "C", value: [1, 2]}
          ]
        )

      assert_selected_multiple_static(component, [
        %{value: %{"x" => 1, "y" => 2}, label: "B"},
        %{value: [1, 2], label: "C"}
      ])
    end

    test "can set initial selection from form without options" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: ["B", "D"]}, %{city_search: {:array, :string}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          form: form,
          field: :city_search
        )

      assert_selected_multiple_static(component, ["B", "D"])
    end

    test "can set initial selection and labels from form without options" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: [{"B", 1}, {"D", 2}]}, %{city_search: {:array, :integer}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          form: form,
          field: :city_search
        )

      assert_selected_multiple_static(component, [
        %{label: "B", value: "1"},
        %{label: "D", value: "2"}
      ])
    end

    test "can set initial selection from form even it can't be found in the options" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: [{"B", 1}, 2, 3]}, %{city_search: {:array, :integer}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          form: form,
          field: :city_search,
          options: [{"D", 2}]
        )

      assert_selected_multiple_static(component, [
        %{label: "B", value: "1"},
        %{label: "D", value: "2"},
        "3"
      ])
    end

    test "can set initial selection explicitly, bypassing the form" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: ["B", "D"]}, %{city_search: {:array, :string}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          form: form,
          field: :city_search,
          value: ["C", "F"],
          options: ["A", "B", "C", "D"]
        )

      assert_selected_multiple_static(component, ["C", "F"])
    end

    test "raises if initial selection is in the wrong format" do
      changeset =
        Ecto.Changeset.change(
          {%{city_search: [%{B: 1, C: 2}]}, %{city_search: {:array, :integer}}},
          %{}
        )

      form = Phoenix.HTML.FormData.to_form(changeset, as: "my_form")

      assert_raise RuntimeError, ~r/invalid element in selection/, fn ->
        render_component(&LiveSelect.live_select/1,
          form: form,
          mode: :tags,
          field: :city_search
        )
      end
    end
  end

  test "raises if invalid assign is passed" do
    assert_raise(RuntimeError, ~r(Invalid assign: "invalid_assign"), fn ->
      render_component(&LiveSelect.live_select/1,
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
        render_component(&LiveSelect.live_select/1,
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
        render_component(&LiveSelect.live_select/1,
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
      ~s(Invalid style: :not_a_valid_style. Style must be one of: [:tailwind, :daisyui, :none]),
      fn ->
        render_component(&LiveSelect.live_select/1,
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
        render_component(&LiveSelect.live_select/1,
          form: :form,
          field: :input,
          options: "not a list"
        )
      end
    )
  end

  test "can be disabled" do
    component =
      render_component(&LiveSelect.live_select/1,
        form: :my_form,
        field: :city_search,
        disabled: true
      )

    assert Floki.attribute(component, selectors()[:text_input], "disabled") == ["disabled"]

    assert Floki.attribute(component, selectors()[:hidden_input], "disabled") == ["disabled"]
  end

  test "can set the debounce value" do
    component =
      render_component(&LiveSelect.live_select/1,
        form: :my_form,
        field: :city_search,
        debounce: 500
      )

    assert Floki.attribute(component, selectors()[:text_input], "phx-debounce") == ["500"]
  end

  test "can set a placeholder text" do
    component =
      render_component(&LiveSelect.live_select/1,
        form: :my_form,
        field: :city_search,
        placeholder: "Give it a try"
      )

    assert Floki.attribute(component, selectors()[:text_input], "placeholder") == [
             "Give it a try"
           ]
  end

  for {override_class, extend_class} <-
        Enum.zip(
          Keyword.values(
            Keyword.drop(override_class_option(), [:available_option, :selected_option])
          ),
          Keyword.values(extend_class_option())
        ) do
    @override_class override_class
    @extend_class extend_class

    test "using both #{@override_class} and #{@extend_class} options raises" do
      assert_raise(
        RuntimeError,
        ~r/`#{@override_class}` and `#{@extend_class}` options can't be used together/,
        fn ->
          opts =
            [
              form: :form,
              field: :input,
              options: ["A", "B", "C"],
              value: ["A", "B"],
              mode: :tags,
              hide_dropdown: false
            ]
            |> Keyword.put(@override_class, "foo")
            |> Keyword.put(@extend_class, "boo")

          render_component(&LiveSelect.live_select/1, opts)
        end
      )
    end
  end

  test "can set class with list" do
    component =
      render_component(
        &LiveSelect.live_select/1,
        [
          form: :my_form,
          field: :city_search,
          options: ["A"],
          hide_dropdown: false
        ] ++ [{override_class_option()[:text_input], ["class_1", "class_2"]}]
      )

    assert Floki.attribute(component, selectors()[:text_input], "class") == [
             "class_1 class_2"
           ]
  end

  for style <- [:daisyui, :tailwind, :none, nil] do
    @style style

    describe "when style = #{@style || "default"}" do
      for element <- [
            :container,
            :text_input,
            :dropdown,
            :option
          ] do
        @element element

        test "#{@element} has default class" do
          component =
            render_component(
              &LiveSelect.live_select/1,
              [
                form: :my_form,
                field: :city_search,
                options: ["A"],
                hide_dropdown: false
              ] ++
                if(@style, do: [style: @style], else: [])
            )

          assert Floki.attribute(component, selectors()[@element], "class") == [
                   get_in(expected_class(), [@style || default_style(), @element]) || ""
                 ]
        end

        if override_class_option()[@element] do
          test "#{@element} class can be overridden with #{override_class_option()[@element]} by passing a string" do
            option = override_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  form: :my_form,
                  field: :city_search,
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     "foo"
                   ]
          end

          test "#{@element} class can be overridden with #{override_class_option()[@element]} by passing a list" do
            option = override_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  form: :my_form,
                  field: :city_search,
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, ["foo", nil, "goo"]}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     "foo goo"
                   ]
          end
        end

        if extend_class_option()[@element] && @style != :none do
          test "#{@element} class can be extended with #{extend_class_option()[@element]} by passing a string" do
            option = extend_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  form: :my_form,
                  field: :city_search,
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     ((get_in(expected_class(), [@style || default_style(), @element]) || "") <>
                        " foo")
                     |> String.trim()
                   ]
          end

          test "#{@element} class can be extended with #{extend_class_option()[@element]} by passing a list" do
            option = extend_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  form: :my_form,
                  field: :city_search,
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, ["foo", nil, "goo"]}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     ((get_in(expected_class(), [@style || default_style(), @element]) || "") <>
                        " foo goo")
                     |> String.trim()
                   ]
          end

          test "single classes of #{@element} class can be removed with !class_name in #{extend_class_option()[@element]}" do
            option = extend_class_option()[@element]

            base_classes = get_in(expected_class(), [@style || default_style(), @element])

            if base_classes do
              class_to_remove = String.split(base_classes) |> List.first()

              expected_classes =
                String.split(base_classes)
                |> Enum.drop(1)
                |> Enum.join(" ")

              component =
                render_component(
                  &LiveSelect.live_select/1,
                  [
                    form: :my_form,
                    field: :city_search,
                    options: ["A"],
                    hide_dropdown: false
                  ] ++
                    if(@style, do: [style: @style], else: []) ++ [{option, "!#{class_to_remove}"}]
                )

              assert Floki.attribute(component, selectors()[@element], "class") == [
                       expected_classes
                     ]
            end
          end
        end
      end

      test "additional class for text input selected is set" do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              form: :my_form,
              field: :city_search,
              options: ["A", "B", "C"],
              value: "A"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        expected_class =
          (get_in(expected_class(), [@style || default_style(), :text_input]) || "") <>
            " " <>
            (get_in(expected_class(), [@style || default_style(), :text_input_selected]) || "")

        assert Floki.attribute(component, selectors()[:text_input], "class") == [
                 String.trim(expected_class)
               ]
      end

      test "additional class for text input selected can be overridden" do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              form: :my_form,
              field: :city_search,
              options: ["A", "B", "C"],
              value: "A",
              text_input_selected_class: "foo"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        expected_class =
          (get_in(expected_class(), [@style || default_style(), :text_input]) || "") <>
            " foo"

        assert Floki.attribute(component, selectors()[:text_input], "class") == [
                 String.trim(expected_class)
               ]
      end

      test "class for selected option is set" do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              form: :my_form,
              mode: :tags,
              field: :city_search,
              options: ["A", "B", "C"],
              value: "B"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        assert_selected_option_class(
          component,
          2,
          get_in(expected_class(), [@style || default_style(), :selected_option]) || ""
        )
      end

      test "class for selected option can be overridden" do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              form: :my_form,
              mode: :tags,
              field: :city_search,
              options: ["A", "B", "C"],
              value: "B",
              selected_option_class: "foo"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        assert_selected_option_class(
          component,
          2,
          "foo"
        )
      end

      test "class for available option is set" do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              form: :my_form,
              mode: :tags,
              field: :city_search,
              options: ["A", "B", "C"],
              value: "B"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        assert_available_option_class(
          component,
          2,
          get_in(expected_class(), [@style || default_style(), :available_option]) || ""
        )
      end

      test "class for available option can be overridden" do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              form: :my_form,
              mode: :tags,
              field: :city_search,
              options: ["A", "B", "C"],
              value: "B",
              available_option_class: "foo"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        assert_available_option_class(
          component,
          2,
          "foo"
        )
      end

      for element <- [
            :tags_container,
            :tag
          ] do
        @element element

        test "#{@element} has default class" do
          component =
            render_component(
              &LiveSelect.live_select/1,
              [
                form: :my_form,
                mode: :tags,
                field: :city_search,
                options: ["A", "B", "C"],
                value: "B"
              ] ++
                if(@style, do: [style: @style], else: [])
            )

          assert Floki.attribute(component, selectors()[@element], "class") == [
                   get_in(expected_class(), [@style || default_style(), @element]) || ""
                 ]
        end

        if override_class_option()[@element] do
          test "#{@element} class can be overridden with #{override_class_option()[@element]}" do
            option = override_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  form: :my_form,
                  mode: :tags,
                  field: :city_search,
                  options: ["A", "B", "C"],
                  value: "B"
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     "foo"
                   ]
          end
        end

        if extend_class_option()[@element] && @style != :none do
          test "#{@element} class can be extended with #{extend_class_option()[@element]}" do
            option = extend_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  form: :my_form,
                  mode: :tags,
                  field: :city_search,
                  options: ["A", "B", "C"],
                  value: "B"
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     ((get_in(expected_class(), [@style || default_style(), @element]) || "") <>
                        " foo")
                     |> String.trim()
                   ]
          end

          test "single classes of #{@element} class can be removed with !class_name in #{extend_class_option()[@element]}" do
            option = extend_class_option()[@element]

            base_classes = get_in(expected_class(), [@style || default_style(), @element])

            if base_classes do
              class_to_remove = String.split(base_classes) |> List.first()

              expected_classes =
                String.split(base_classes)
                |> Enum.drop(1)
                |> Enum.join(" ")

              component =
                render_component(
                  &LiveSelect.live_select/1,
                  [
                    form: :my_form,
                    mode: :tags,
                    field: :city_search,
                    options: ["A", "B", "C"],
                    value: "B"
                  ] ++
                    if(@style, do: [style: @style], else: []) ++ [{option, "!#{class_to_remove}"}]
                )

              assert Floki.attribute(component, selectors()[@element], "class") == [
                       expected_classes
                     ]
            end
          end
        end
      end
    end
  end
end
