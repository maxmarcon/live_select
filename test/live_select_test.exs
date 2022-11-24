defmodule LiveSelectTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect.TestHelpers
  import LiveSelect
  import Mox

  alias LiveSelect.ChangeMsg

  @default_style :tailwind

  @expected_class [
    daisyui: [
      active_option: ~S(active),
      container: ~S(dropdown dropdown-open),
      dropdown: ~S(dropdown-content menu menu-compact shadow rounded-box bg-base-200 p-1 w-full),
      text_input: ~S(input input-bordered w-full),
      text_input_selected: ~S(input-primary text-primary)
    ],
    tailwind: [
      active_option: ~S(text-white bg-gray-600),
      container: ~S(relative h-full text-black),
      dropdown: ~S(absolute rounded-xl shadow z-50 bg-gray-100 w-full),
      option: ~S(rounded-lg px-4 py-1 hover:bg-gray-400),
      text_input:
        ~S(rounded-md h-full w-full disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400),
      text_input_selected: ~S(border-gray-600 text-gray-600 border-2)
    ]
  ]

  @override_class_option [
    container: :container_class,
    text_input: :text_input_class,
    dropdown: :dropdown_class,
    option: :option_class
  ]

  @extend_class_option [
    container: :container_extra_class,
    text_input: :text_input_extra_class,
    dropdown: :dropdown_extra_class,
    option: :option_extra_class
  ]

  @selectors [
    container: "div[name=live-select]",
    text_input: "input#my_form_city_search_text_input[type=text]",
    dropdown: "ul[name=live-select-dropdown]",
    dropdown_entries: "ul[name=live-select-dropdown] > li > div",
    option: "ul[name=live-select-dropdown] > li:first-of-type > div",
    hidden_input: "input#my_form_city_search[type=hidden]"
  ]

  setup :verify_on_exit!

  test "can be rendered", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    assert has_element?(live, "input#my_form_city_search[type=hidden]")

    assert has_element?(live, "input#my_form_city_search_text_input[type=text]")
  end

  test "can be rendered with a given field name", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?field_name=city_search")

    assert has_element?(live, "input#my_form_city_search[type=hidden]")

    assert has_element?(live, "input#my_form_city_search_text_input[type=text]")
  end

  test "can be rendered with a given form name", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?form_name=special_form")

    assert has_element?(live, "input#special_form_city_search[type=hidden]")

    assert has_element?(live, "input#special_form_city_search_text_input[type=text]")
  end

  test "sends a ChangeMsg message as reaction to user's input", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    Mox.expect(LiveSelect.MessageHandlerMock, :handle, fn %ChangeMsg{
                                                            id: "my_form_city_search_component",
                                                            text: "Ber",
                                                            module: LiveSelect.Component,
                                                            field: :city_search
                                                          },
                                                          _ ->
      nil
    end)

    type(live, "Ber")
  end

  test "with less than 3 keystrokes in the input field it does not show the dropdown", %{
    conn: conn
  } do
    {:ok, live, _html} = live(conn, "/")

    type(live, "Be")

    assert_option_size(live, 0)
  end

  test "with at least 3 keystrokes in the input field it does show the dropdown", %{conn: conn} do
    stub_options(["A", "B", "C"])

    {:ok, live, _html} = live(conn, "/")

    type(live, "Ber")

    assert_option_size(live, &(&1 > 0))
  end

  test "number of minimum keystrokes can be configured", %{conn: conn} do
    stub_options(["A", "B", "C"])

    {:ok, live, _html} = live(conn, "/?update_min_len=4")

    type(live, "Ber")

    assert_option_size(live, 0)

    type(live, "Berl")

    assert_option_size(live, &(&1 > 0))
  end

  test "supports dropdown filled with tuples", %{conn: conn} do
    stub_options([{"A", 1}, {"B", 2}, {"C", 3}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "can select option with mouseclick", %{conn: conn} do
    stub_options([{"A", 1}, {"B", 2}, {"C", 3}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2, :click)

    assert_option_selected(live, "B", 2)
  end

  test "supports dropdown filled with strings", %{conn: conn} do
    stub_options(["A", "B", "C"])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B")
  end

  test "supports dropdown filled with atoms", %{conn: conn} do
    stub_options([:A, :B, :C])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, :B)
  end

  test "supports dropdown filled with integers", %{conn: conn} do
    stub_options([1, 2, 3])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, [1, 2, 3])

    select_nth_option(live, 2)

    assert_option_selected(live, 2)
  end

  test "supports dropdown filled with keywords", %{conn: conn} do
    stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "supports dropdown filled with values from keyword list", %{conn: conn} do
    stub_options(
      A: 1,
      B: 2,
      C: 3
    )

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, :B, 2)
  end

  test "supports dropdown filled with values from map", %{conn: conn} do
    stub_options(%{A: 1, B: 2, C: 3})

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, :B, 2)
  end

  test "supports dropdown filled from an enumerable of maps", %{conn: conn} do
    stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, %{label: "C", value: 3}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "supports dropdown filled from an enumerable of keywords", %{conn: conn} do
    stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "supports dropdown filled with keywords with key as the label", %{conn: conn} do
    stub_options([[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "can specify a value to be sent when nothing is selected via default_value", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?default_value=default")

    hidden_input =
      live
      |> element(@selectors[:hidden_input])
      |> render()
      |> Floki.parse_fragment!()

    assert Floki.attribute(hidden_input, "value") == ["default"]
  end

  test "clicking on the text input field resets the selection", %{conn: conn} do
    stub_options(
      A: 1,
      B: 2,
      C: 3
    )

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_option_selected(live, :B, 2)

    element(live, @selectors[:text_input])
    |> render_click()

    assert_reset(live)
  end

  test "reset takes into account the default_value", %{conn: conn} do
    stub_options(
      A: 1,
      B: 2,
      C: 3
    )

    {:ok, live, _html} = live(conn, "/?default_value=foo")

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_option_selected(live, :B, 2)

    element(live, @selectors[:text_input])
    |> render_click()

    assert_reset(live, "foo")
  end

  test "can navigate options with arrows", %{conn: conn} do
    stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/?style=daisyui")

    type(live, "ABC")

    navigate(live, 4, :down)
    navigate(live, 1, :up)

    assert_option_active(live, 1)
  end

  test "moving the mouse on the dropdown deactivate option", %{conn: conn} do
    stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/?style=daisyui")

    type(live, "ABC")

    navigate(live, 1, :down)

    assert_option_active(live, 0)

    dropdown_mouseover(live)

    assert_option_active(live, -1)
  end

  test "dropdown becomes visible when typing", %{conn: conn} do
    stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/?style=daisyui")

    type(live, "ABC")

    assert dropdown_visible(live)
  end

  describe "when the dropdown is visible" do
    setup %{conn: conn} do
      stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

      {:ok, live, _html} = live(conn, "/?style=daisyui")

      type(live, "ABC")

      assert dropdown_visible(live)

      %{live: live}
    end

    test "blur on text input hides it", %{live: live} do
      render_blur(element(live, @selectors[:text_input]))

      refute dropdown_visible(live)
    end

    test "pressing the escape key hides it", %{live: live} do
      keydown(live, "Escape")

      refute dropdown_visible(live)
    end

    test "if the mouse is on the dropdown blur on text input does not hide it", %{live: live} do
      dropdown_mouseover(live)

      render_blur(element(live, @selectors[:text_input]))

      assert dropdown_visible(live)
    end

    test "if the mouse is on the dropdown the escape key does not hide it", %{live: live} do
      dropdown_mouseover(live)

      keydown(live, "Escape")

      assert dropdown_visible(live)
    end
  end

  describe "when the dropdown is hidden" do
    setup %{conn: conn} do
      stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

      {:ok, live, _html} = live(conn, "/?style=daisyui")

      type(live, "ABC")

      render_blur(element(live, @selectors[:text_input]))

      refute dropdown_visible(live)

      %{live: live}
    end

    test "focus on text input shows it", %{live: live} do
      render_focus(element(live, @selectors[:text_input]))

      assert dropdown_visible(live)
    end

    test "clicking on the input shows it", %{live: live} do
      render_click(element(live, @selectors[:text_input]))

      assert dropdown_visible(live)
    end

    test "pressing a key shows it", %{live: live} do
      keydown(live, "ArrowDown")

      assert dropdown_visible(live)
    end

    test "pressing escape doesn't show it ", %{live: live} do
      keydown(live, "Escape")

      refute dropdown_visible(live)
    end

    test "typing shows it", %{live: live} do
      type(live, "something")

      assert dropdown_visible(live)
    end
  end

  test "can be disabled", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?disabled=true")

    assert element(live, @selectors[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("disabled") == ["disabled"]

    assert element(live, @selectors[:hidden_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("disabled") == ["disabled"]
  end

  test "can set the debounce value", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?debounce=500")

    assert element(live, @selectors[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("phx-debounce") == ["500"]
  end

  test "can set a placeholder text", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?placeholder=Give it a try")

    assert element(live, @selectors[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("placeholder") == ["Give it a try"]
  end

  test "raises if unknown style is given" do
    assert_raise(
      RuntimeError,
      ~s(Invalid style: "not_a_valid_style". Style must be one of: [:daisyui, :tailwind, :none]),
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

  for {override_class, extend_class} <-
        Enum.zip(Keyword.values(@override_class_option), Keyword.values(@extend_class_option)),
      # we must open the dropdown to test option_class
      override_class != :option_class do
    @override_class override_class
    @extend_class extend_class

    test "using both #{@override_class} and #{@extend_class} options raises" do
      assert_raise(
        RuntimeError,
        ~r/`#{@override_class}` and `#{@extend_class}` options can't be used together/,
        fn ->
          opts =
            [id: "live_select", form: :form, field: :input]
            |> Keyword.put(@override_class, "foo")
            |> Keyword.put(@extend_class, "boo")

          render_component(LiveSelect.Component, opts)
        end
      )
    end
  end

  for style <- [:daisyui, :tailwind, :none, nil] do
    @style style

    describe "when style = #{@style || "default"}" do
      setup do
        stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, %{label: "C", value: 3}])
      end

      if @style == :none do
        test "using _extra_class option raises", %{conn: conn} do
          assert_raise RuntimeError,
                       ~r/when using `style: :none`, please use only `container_class`/i,
                       fn ->
                         live(conn, "/?style=#{@style}&container_extra_class=boo")
                       end
        end
      end

      for element <- [
            :container,
            :text_input,
            :dropdown,
            :option
          ] do
        @element element

        test "#{@element} has default class", %{conn: conn} do
          {:ok, live, _html} = live(conn, "/?style=#{@style}")

          type(live, "ABC")

          assert element(live, @selectors[@element])
                 |> render()
                 |> Floki.parse_fragment!()
                 |> Floki.attribute("class") == [
                   get_in(@expected_class, [@style || @default_style, @element]) || ""
                 ]
        end

        if @override_class_option[@element] do
          test "#{@element} class can be overridden with #{@override_class_option[@element]}", %{
            conn: conn
          } do
            option = @override_class_option[@element]

            {:ok, live, _html} = live(conn, "/?style=#{@style}&#{option}=foo")

            type(live, "ABC")

            assert element(live, @selectors[@element])
                   |> render()
                   |> Floki.parse_fragment!()
                   |> Floki.attribute("class") == [
                     "foo"
                   ]
          end
        end

        if @extend_class_option[@element] && @style != :none do
          test "#{@element} class can be extended with #{@extend_class_option[@element]}", %{
            conn: conn
          } do
            option = @extend_class_option[@element]

            {:ok, live, _html} = live(conn, "/?style=#{@style}&#{option}=foo")

            type(live, "ABC")

            assert element(live, @selectors[@element])
                   |> render()
                   |> Floki.parse_fragment!()
                   |> Floki.attribute("class") == [
                     ((get_in(@expected_class, [@style || @default_style, @element]) || "") <>
                        " foo")
                     |> String.trim()
                   ]
          end

          test "single classes of #{@element} class can be removed with !class_name in #{@extend_class_option[@element]}",
               %{
                 conn: conn
               } do
            option = @extend_class_option[@element]

            base_classes = get_in(@expected_class, [@style || @default_style, @element])

            if base_classes do
              class_to_remove = String.split(base_classes) |> List.first()

              expected_classes =
                String.split(base_classes)
                |> Enum.drop(1)
                |> Enum.join(" ")

              {:ok, live, _html} = live(conn, "/?style=#{@style}&#{option}=!#{class_to_remove}")

              type(live, "ABC")

              assert element(live, @selectors[@element])
                     |> render()
                     |> Floki.parse_fragment!()
                     |> Floki.attribute("class") == [
                       expected_classes
                     ]
            end
          end
        end
      end

      test "class for active option is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}")

        type(live, "ABC")

        navigate(live, 1, :down)

        assert_option_active(
          live,
          0,
          get_in(@expected_class, [@style || @default_style, :active_option]) || ""
        )
      end

      test "class for active option can be overriden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&active_option_class=foo")

        type(live, "ABC")

        navigate(live, 1, :down)

        assert_option_active(
          live,
          0,
          "foo"
        )
      end

      test "additional class for text input selected is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}")

        type(live, "ABC")

        select_nth_option(live, 1)

        expected_class =
          (get_in(@expected_class, [@style || @default_style, :text_input]) || "") <>
            " " <>
            (get_in(@expected_class, [@style || @default_style, :text_input_selected]) || "")

        assert element(live, @selectors[:text_input])
               |> render()
               |> Floki.parse_fragment!()
               |> Floki.attribute("class") == [
                 expected_class
               ]
      end

      test "additional class for text input selected can be overridden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&text_input_selected_class=foo")

        type(live, "ABC")

        select_nth_option(live, 1)

        expected_class =
          (get_in(@expected_class, [@style || @default_style, :text_input]) || "") <>
            " foo"

        assert element(live, @selectors[:text_input])
               |> render()
               |> Floki.parse_fragment!()
               |> Floki.attribute("class") == [
                 expected_class
               ]
      end
    end
  end
end
