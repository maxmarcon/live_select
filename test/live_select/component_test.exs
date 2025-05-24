defmodule LiveSelect.ComponentTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true
  import LiveSelect.TestHelpers

  alias LiveSelect.City

  setup tags do
    %{form: Phoenix.Component.to_form(tags[:source] || %{}, as: :my_form)}
  end

  test "can be rendered", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        field: form[:live_select]
      )
      |> Floki.parse_document!()

    assert component
           |> Floki.find("input#my_form_live_select")
           |> Enum.any?()

    assert component
           |> Floki.find("input#my_form_live_select_text_input")
           |> Enum.any?()
  end

  test "can be rendered using old-style form/field assigns", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        form: form,
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

  test "can be rendered using old-style form/field assigns and an atom form" do
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

  test "can set initial options", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        field: form[:input],
        options: ["A", "B", "C"],
        hide_dropdown: false
      )

    assert_options(component, ["A", "B", "C"])
  end

  test "can be rendered with a custom id", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        id: "live_select_custom_id",
        field: form[:search],
        update_min_len: 3,
        "phx-target": "1",
        debounce: 100
      )
      |> Floki.parse_fragment!()

    assert Floki.attribute(component, "data-field") == ["my_form_search"]
    assert Floki.attribute(component, "data-update-min-len") == ["3"]
    assert Floki.attribute(component, "data-phx-target") == ["1"]

    assert Floki.attribute(component, "data-debounce") == ["100"]
  end

  test "renders data attributes", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        id: "live_select_custom_id",
        field: form[:input]
      )

    assert length(Floki.find(component, "#live_select_custom_id")) == 1
  end

  describe "in single mode" do
    @tag source: %{"city_search" => "B"}
    test "can set selection from the form", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search],
          options: ["A", "B", "C"]
        )

      assert_selected_static(component, "B")
    end

    @tag source: %{"city_search" => %{"x" => 1, "y" => 2}}
    test "can set selection from form for non-string values", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search],
          options: [
            %{label: "A", value: %{}},
            %{label: "B", value: %{"x" => 1, "y" => 2}},
            %{label: "C", value: [1, 2]}
          ]
        )

      assert_selected_static(component, "B", %{"x" => 1, "y" => 2})
    end

    @tag source: %{"city_search" => "B"}
    test "can set selection from form without options", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search]
        )

      assert_selected_static(component, "B")
    end

    @tag source: %{"city_search" => {"B", 1}}
    test "can set selection and label from form without options", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search]
        )

      assert_selected_static(component, "B", 1)
    end

    @tag source: %{"city_search" => "A"}
    test "can set selection from form even if it can't be found in the options", %{
      form: form
    } do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search],
          options: ["B"]
        )

      assert_selected_static(component, "A")
    end

    @tag source: %{
           "city_search" =>
             Ecto.Changeset.change(%City{name: "New York"}, %{name: "Berlin", pos: [10, 20]})
         }
    test "can set selection from form with changeset", %{
      form: form
    } do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search],
          value_mapper: fn %{name: name, pos: pos} ->
            %{label: name, value: %{name: name, pos: pos}}
          end
        )

      assert_selected_static(component, "Berlin", %{name: "Berlin", pos: [10, 20]})
    end

    @tag source: %{"city_search" => %{name: "Max", age: 40}}
    test "applies value_mapper to the selection in the form", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search],
          value_mapper: fn %{name: name, age: age} -> %{label: name, value: age} end
        )

      assert_selected_static(component, "Max", 40)
    end

    @tag source: %{"city_search" => 2}
    test "can set initial selection explicitly, bypassing the form", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          field: form[:city_search],
          value: 3,
          options: [{"A", 1}, {"B", 2}, {"C", 3}]
        )

      assert_selected_static(component, "C", 3)
    end
  end

  describe "in tags mode" do
    @tag source: %{"city_search" => ["B", "D"]}
    test "can set selection from form", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          options: ["A", "B", "C", "D"]
        )

      assert_selected_multiple_static(component, ["B", "D"])
    end

    @tag source: %{"city_search" => [%{"x" => 1, "y" => 2}, [1, 2]]}
    test "can set selection from form for non-string values", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
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

    @tag source: %{"city_search" => ["B", "D"]}
    test "can set selection from form without options", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search]
        )

      assert_selected_multiple_static(component, ["B", "D"])
    end

    @tag source: %{"city_search" => [{"B", 1}, {"D", 2}]}
    test "can set selection and labels from form without options", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search]
        )

      assert_selected_multiple_static(component, [
        %{label: "B", value: "1"},
        %{label: "D", value: "2"}
      ])
    end

    @tag source: %{"city_search" => [1, 2]}
    test "can set selection from form using labels from options", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          options: [{"B", 1}, {"D", 2}]
        )

      assert_selected_multiple_static(component, [
        %{label: "B", value: "1"},
        %{label: "D", value: "2"}
      ])
    end

    @tag source: %{"city_search" => [{"B", 1}, 2, 3]}
    test "can set selection from form even it can't be found in the options", %{
      form: form
    } do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          options: [{"D", 2}]
        )

      assert_selected_multiple_static(component, [
        %{label: "B", value: "1"},
        %{label: "D", value: "2"},
        "3"
      ])
    end

    @tag source: %{
           "city_search" => [
             Ecto.Changeset.change(%City{}, %{name: "Berlin", pos: [10, 20]}),
             Ecto.Changeset.change(%City{}, %{name: "Rome", pos: [30, 40]})
           ]
         }
    test "can set selection from form with changeset", %{
      form: form
    } do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          value_mapper: fn %{name: name, pos: pos} ->
            %{label: name, value: %{name: name, pos: pos}}
          end
        )

      assert_selected_multiple_static(component, [
        %{label: "Berlin", value: %{name: "Berlin", pos: [10, 20]}},
        %{label: "Rome", value: %{name: "Rome", pos: [30, 40]}}
      ])
    end

    @tag source: %{"city_search" => [%{name: "Max", age: 40}, %{name: "Julia", age: 30}]}
    test "applies value_mapper to the selection in the form", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          value_mapper: fn %{name: name, age: age} -> %{label: name, value: age} end
        )

      assert_selected_multiple_static(component, [
        %{label: "Max", value: 40},
        %{label: "Julia", value: 30}
      ])
    end

    @tag source: %{
           "city_search" => [
             Ecto.Changeset.change(%City{}, %{name: "New York", pos: [5, 2]})
             |> then(&%{&1 | action: :replace}),
             Ecto.Changeset.change(%City{name: "Venice"}, %{name: "Berlin", pos: [10, 20]}),
             Ecto.Changeset.change(%City{}, %{name: "Rome", pos: [30, 40]})
           ]
         }
    test "can set selection from form with changeset ignoring replace changesets", %{
      form: form
    } do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          value_mapper: fn %{name: name, pos: pos} ->
            %{label: name, value: %{name: name, pos: pos}}
          end
        )

      assert_selected_multiple_static(component, [
        %{label: "Berlin", value: %{name: "Berlin", pos: [10, 20]}},
        %{label: "Rome", value: %{name: "Rome", pos: [30, 40]}}
      ])
    end

    @tag source: %{"city_search" => [{"B", 2}, {"D", 4}]}
    test "can set initial selection explicitly, bypassing the form", %{form: form} do
      component =
        render_component(&LiveSelect.live_select/1,
          mode: :tags,
          field: form[:city_search],
          value: [1, 3],
          options: [{"A", 1}, {"B", 2}, {"C", 3}, {"D", 4}]
        )

      assert_selected_multiple_static(component, [
        %{label: "A", value: 1},
        %{label: "C", value: 3}
      ])
    end
  end

  test "raises if options are passed in the wrong format (1)", %{form: form} do
    assert_raise RuntimeError, ~r/invalid element in option/, fn ->
      render_component(&LiveSelect.live_select/1,
        field: form[:city_search],
        options: [[10, 20]]
      )
    end
  end

  test "raises if options are passed in the wrong format (2)", %{form: form} do
    assert_raise RuntimeError, ~r/invalid element in option/, fn ->
      render_component(&LiveSelect.live_select/1,
        field: form[:city_search],
        options: [%{x: 10, y: 20}]
      )
    end
  end

  test "raises if an atom field is passed without a form" do
    assert_raise(
      RuntimeError,
      "if you pass field as atom or string, you also have to pass a form",
      fn ->
        render_component(&LiveSelect.live_select/1, field: :atom_field)
      end
    )
  end

  test "raises if invalid assign is passed", %{form: form} do
    assert_raise(RuntimeError, ~r(Invalid assign: "invalid_assign"), fn ->
      render_component(&LiveSelect.live_select/1,
        field: form[:live_select],
        invalid_assign: "foo"
      )
    end)
  end

  test "raises if _extra_class option is used with styles == :none", %{form: form} do
    assert_raise(
      RuntimeError,
      ~r/when using `style: :none`, please use only `container_class`/i,
      fn ->
        render_component(&LiveSelect.live_select/1,
          field: form[:live_select],
          style: :none,
          container_extra_class: "foo"
        )
      end
    )
  end

  test "raises if unknown mode is given", %{form: form} do
    assert_raise(
      RuntimeError,
      ~s(Invalid mode: "not_a_valid_mode". Mode must be one of: [:single, :tags, :quick_tags]),
      fn ->
        render_component(&LiveSelect.live_select/1,
          field: form[:input],
          mode: :not_a_valid_mode
        )
      end
    )
  end

  test "raises if unknown style is given", %{form: form} do
    assert_raise(
      RuntimeError,
      ~s(Invalid style: :not_a_valid_style. Style must be one of: [:tailwind, :daisyui, :none]),
      fn ->
        render_component(&LiveSelect.live_select/1,
          field: form[:input],
          style: :not_a_valid_style
        )
      end
    )
  end

  test "raises if non-enumerable options are given", %{form: form} do
    assert_raise(
      RuntimeError,
      ~s(options must be enumerable),
      fn ->
        render_component(&LiveSelect.live_select/1,
          field: form[:input],
          options: "not a list"
        )
      end
    )
  end

  test "can be disabled", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        field: form[:city_search],
        disabled: true
      )

    assert Floki.attribute(component, selectors()[:text_input], "disabled") == ["disabled"]

    assert Floki.attribute(component, selectors()[:hidden_input], "disabled") == ["disabled"]
  end

  test "can set a placeholder text", %{form: form} do
    component =
      render_component(&LiveSelect.live_select/1,
        field: form[:city_search],
        placeholder: "Give it a try"
      )

    assert Floki.attribute(component, selectors()[:text_input], "placeholder") == [
             "Give it a try"
           ]
  end

  for {override_class, extend_class} <-
        Enum.zip(
          Keyword.values(
            Keyword.drop(override_class_option(), [
              :available_option,
              :unavailable_option,
              :selected_option
            ])
          ),
          Keyword.values(extend_class_option())
        ) do
    @override_class override_class
    @extend_class extend_class

    test "using both #{@override_class} and #{@extend_class} options raises", %{form: form} do
      assert_raise(
        RuntimeError,
        ~r/`#{@override_class}` and `#{@extend_class}` options can't be used together/,
        fn ->
          opts =
            [
              field: form[:input],
              options: ["A", "B", "C"],
              value: ["A", "B"],
              allow_clear: @override_class == :clear_button_class,
              mode: if(@override_class == :clear_button_class, do: :single, else: :tags),
              hide_dropdown: false
            ]
            |> Keyword.put(@override_class, "foo")
            |> Keyword.put(@extend_class, "boo")

          render_component(&LiveSelect.live_select/1, opts)
        end
      )
    end
  end

  test "can set class with list", %{form: form} do
    component =
      render_component(
        &LiveSelect.live_select/1,
        [
          field: form[:city_search],
          options: ["A"],
          hide_dropdown: false
        ] ++ [{override_class_option()[:text_input], ["class_1", "class_2"]}]
      )

    assert Floki.attribute(component, selectors()[:text_input], "class") == [
             "class_1 class_2"
           ]
  end

  for style <- [nil] do
    @style style

    describe "when style = #{@style || "default"}" do
      for element <- [
            :container,
            :text_input,
            :dropdown,
            :option
          ] do
        @element element

        test "#{@element} has default class", %{form: form} do
          component =
            render_component(
              &LiveSelect.live_select/1,
              [
                field: form[:city_search],
                options: ["A"],
                hide_dropdown: false
              ] ++
                if(@style, do: [style: @style], else: [])
            )

          assert Floki.attribute(component, selectors()[@element], "class") == [
                   (get_in(expected_class(), [@style || default_style(), @element]) || [])
                   |> Enum.join(" ")
                 ]
        end

        if override_class_option()[@element] do
          test "#{@element} class can be overridden with #{override_class_option()[@element]} by passing a string",
               %{form: form} do
            option = override_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  field: form[:city_search],
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") ==
                     ~W(foo)
          end

          test "#{@element} class can be overridden with #{override_class_option()[@element]} by passing a list",
               %{form: form} do
            option = override_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  field: form[:city_search],
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, ["foo", nil, "goo"]}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") ==
                     ["foo goo"]
          end
        end

        if extend_class_option()[@element] && @style != :none do
          test "#{@element} class can be extended with #{extend_class_option()[@element]} by passing a string",
               %{form: form} do
            option = extend_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  field: form[:city_search],
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     ((get_in(expected_class(), [@style || default_style(), @element]) || []) ++
                        ~W(foo))
                     |> Enum.join(" ")
                   ]
          end

          test "#{@element} class can be extended with #{extend_class_option()[@element]} by passing a list",
               %{form: form} do
            option = extend_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  field: form[:city_search],
                  options: ["A"],
                  hide_dropdown: false
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, ["foo", nil, "goo"]}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     ((get_in(expected_class(), [@style || default_style(), @element]) || []) ++
                        ~W(foo goo))
                     |> Enum.join(" ")
                   ]
          end

          test "single classes of #{@element} class can be removed with !class_name in #{extend_class_option()[@element]}",
               %{form: form} do
            option = extend_class_option()[@element]

            base_classes = get_in(expected_class(), [@style || default_style(), @element])

            if base_classes do
              class_to_remove = base_classes |> List.first()

              expected_classes =
                base_classes
                |> Enum.drop(1)
                |> Enum.join(" ")

              component =
                render_component(
                  &LiveSelect.live_select/1,
                  [
                    field: form[:city_search],
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

      test "additional class for text input selected is set", %{form: form} do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              field: form[:city_search],
              options: ["A", "B", "C"],
              value: "A"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        expected_class =
          ((get_in(expected_class(), [@style || default_style(), :text_input]) || []) ++
             (get_in(expected_class(), [@style || default_style(), :text_input_selected]) || []))
          |> Enum.join(" ")

        assert Floki.attribute(component, selectors()[:text_input], "class") == [
                 expected_class
               ]
      end

      test "additional class for text input selected can be overridden", %{form: form} do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              field: form[:city_search],
              options: ["A", "B", "C"],
              value: "A",
              text_input_selected_class: "foo"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        expected_class =
          ((get_in(expected_class(), [@style || default_style(), :text_input]) || []) ++
             ~W(foo))
          |> Enum.join(" ")

        assert Floki.attribute(component, selectors()[:text_input], "class") == [
                 String.trim(expected_class)
               ]
      end

      test "class for clear button can be overridden", %{form: form} do
        component =
          render_component(
            &LiveSelect.live_select/1,
            [
              mode: :single,
              field: form[:city_search],
              options: ["A", "B", "C"],
              value: "B",
              allow_clear: true,
              clear_button_class: "foo"
            ] ++
              if(@style, do: [style: @style], else: [])
          )

        assert Floki.attribute(component, selectors()[:clear_button], "class") == ~W(foo)
      end

      if @style != :none do
        test "class for clear button can be extended", %{form: form} do
          component =
            render_component(
              &LiveSelect.live_select/1,
              [
                mode: :single,
                field: form[:city_search],
                options: ["A", "B", "C"],
                value: "B",
                allow_clear: true,
                clear_button_extra_class: "foo"
              ] ++
                if(@style, do: [style: @style], else: [])
            )

          assert Floki.attribute(component, selectors()[:clear_button], "class") == [
                   ((get_in(expected_class(), [@style || default_style(), :clear_button]) || []) ++
                      ~W(foo))
                   |> Enum.join(" ")
                   |> String.trim()
                 ]
        end
      end

      for element <- [
            :tags_container,
            :tag,
            :clear_tag_button
          ] do
        @element element

        test "#{@element} has default class", %{form: form} do
          component =
            render_component(
              &LiveSelect.live_select/1,
              [
                mode: :tags,
                field: form[:city_search],
                options: ["A", "B", "C"],
                value: "B"
              ] ++
                if(@style, do: [style: @style], else: [])
            )

          assert Floki.attribute(component, selectors()[@element], "class") == [
                   (get_in(expected_class(), [@style || default_style(), @element]) || [])
                   |> Enum.join(" ")
                 ]
        end

        if override_class_option()[@element] do
          test "#{@element} class can be overridden with #{override_class_option()[@element]}", %{
            form: form
          } do
            option = override_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  mode: :tags,
                  field: form[:city_search],
                  options: ["A", "B", "C"],
                  value: "B"
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == ~w(foo)
          end
        end

        if extend_class_option()[@element] && @style != :none do
          test "#{@element} class can be extended with #{extend_class_option()[@element]}", %{
            form: form
          } do
            option = extend_class_option()[@element]

            component =
              render_component(
                &LiveSelect.live_select/1,
                [
                  mode: :tags,
                  field: form[:city_search],
                  options: ["A", "B", "C"],
                  value: "B"
                ] ++
                  if(@style, do: [style: @style], else: []) ++ [{option, "foo"}]
              )

            assert Floki.attribute(component, selectors()[@element], "class") == [
                     ((get_in(expected_class(), [@style || default_style(), @element]) || []) ++
                        ~W(foo))
                     |> Enum.join(" ")
                     |> String.trim()
                   ]
          end

          test "single classes of #{@element} class can be removed with !class_name in #{extend_class_option()[@element]}",
               %{form: form} do
            option = extend_class_option()[@element]

            base_classes = get_in(expected_class(), [@style || default_style(), @element])

            if base_classes do
              class_to_remove = base_classes |> List.first()

              expected_classes =
                base_classes
                |> Enum.drop(1)
                |> Enum.join(" ")

              component =
                render_component(
                  &LiveSelect.live_select/1,
                  [
                    mode: :tags,
                    field: form[:city_search],
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

      test "daisyui style includes both active and menu-active classes for compatibility", %{
        form: form
      } do
        # Render the component with daisyui style
        component =
          render_component(&LiveSelect.live_select/1,
            field: form[:city_search],
            options: ["A", "B", "C"],
            style: :daisyui,
            hide_dropdown: false
          )
          |> Floki.parse_document!()

        # Find the first option div
        option_divs = Floki.find(component, "div[data-idx]")
        assert length(option_divs) > 0

        # Get the default active option classes for daisyui
        active_classes = LiveSelect.Component.default_class(:daisyui, :active_option)

        # Verify both classes are in the defaults
        assert "active" in active_classes
        assert "menu-active" in active_classes
      end
    end
  end
end
