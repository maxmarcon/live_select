defmodule LiveSelectTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect.TestHelpers
  import Mox

  doctest LiveSelect, import: true

  setup :verify_on_exit!

  test "can be rendered", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    assert has_element?(live, selectors()[:hidden_input])

    assert has_element?(live, selectors()[:text_input])
  end

  test "can be rendered with a given field name", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?field_name=city_search")

    assert has_element?(live, selectors()[:hidden_input])

    assert has_element?(live, selectors()[:text_input])
  end

  test "with less than update_min_len keystrokes in the input field it does not show the dropdown",
       %{
         conn: conn
       } do
    {:ok, live, _html} = live(conn, "/?update_min_len=3")

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

    type(live, "Ber", update_min_len: 4)

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

    assert_selected(live, "B", 2)
  end

  test "can select option with mouseclick", %{conn: conn} do
    stub_options([{"A", 1}, {"B", 2}, {"C", 3}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2, method: :click)

    assert_selected(live, "B", 2)
  end

  test "selecting option with enter sends blur event to parent", %{conn: conn} do
    stub_options([{"A", 1}, {"B", 2}, {"C", 3}])

    {:ok, live, _html} = live(conn, "/?phx-blur=blur-event-for-parent")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2, method: :key)

    assert_push_event(live, "select", %{
      id: "my_form_city_search_live_select_component",
      parent_event: "blur-event-for-parent"
    })
  end

  test "selecting option with click sends blur event to parent", %{conn: conn} do
    stub_options([{"A", 1}, {"B", 2}, {"C", 3}])

    {:ok, live, _html} = live(conn, "/?phx-blur=blur-event-for-parent")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2, method: :click)

    assert_push_event(live, "select", %{
      id: "my_form_city_search_live_select_component",
      parent_event: "blur-event-for-parent"
    })
  end

  test "hitting enter with only one option selects it", %{conn: conn} do
    stub_options([{"A", 1}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A"])

    keydown(live, "Enter")

    assert_selected(live, "A", 1)
  end

  test "hitting enter with more than one option does not select", %{conn: conn} do
    stub_options([{"A", 1}, {"B", 2}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B"])

    keydown(live, "Enter")

    refute_selected(live)
  end

  describe "when user_defined_options = true" do
    setup %{conn: conn} do
      {:ok, live, _html} = live(conn, "/?user_defined_options=true")

      %{live: live}
    end

    test "hitting enter adds entered text to selection", %{live: live} do
      stub_options(~w(A B))

      type(live, "ABC")

      assert_options(live, ["A", "B"])

      keydown(live, "Enter")

      assert_selected(live, "ABC")
    end

    test "text added to selection should be trimmed", %{live: live} do
      stub_options([])

      type(live, " ABC  ")

      assert_options(live, [])

      keydown(live, "Enter")

      assert_selected(live, "ABC")
    end

    test "hitting enter while options are awaiting update does not select", %{live: live} do
      stub_options([{"A", 1}, {"B", 2}], delay_forever: true)

      type(live, "ABC")

      keydown(live, "Enter")

      refute_selected(live)
    end
  end

  describe "when allow_clear is set" do
    setup %{conn: conn} do
      {:ok, live, _html} = live(conn, "/?allow_clear=true")

      %{live: live}
    end

    test "clicking on clear button clears the selection", %{live: live} do
      stub_options([{"A", 1}, {"B", 1}])

      type(live, "ABC")

      select_nth_option(live, 1)

      assert_selected(live, "A", 1)

      element(live, "#{selectors()[:container]} [phx-click=clear]")
      |> render_click()

      assert_clear(live)
    end
  end

  test "the clear button can be disabled", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?allow_clear=true&disabled=true")

    stub_options([{"A", 1}, {"B", 1}])

    type(live, "ABC")

    select_nth_option(live, 1)

    assert element(live, selectors()[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("disabled") == ["disabled"]

    assert element(live, selectors()[:hidden_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("disabled") == ["disabled"]

    refute has_element?(live, selectors()[:clear_button])
  end

  test "can render custom clear button", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/live_component_test")

    type(live, "Ber",
      component: "#my_form_city_search_custom_clear_single_live_select_component",
      parent: "#form_component"
    )

    select_nth_option(live, 1,
      component: "#my_form_city_search_custom_clear_single_live_select_component"
    )

    assert element(
             live,
             "#my_form_city_search_custom_clear_single_live_select_component button[phx-click=clear]",
             "custom clear button"
           )
           |> has_element?
  end

  test "supports dropdown filled with strings", %{conn: conn} do
    stub_options(["A", "B", "C"])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, "B")
  end

  test "supports dropdown filled with atoms", %{conn: conn} do
    stub_options([:A, :B, :C])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, :B)
  end

  test "supports dropdown filled with integers", %{conn: conn} do
    stub_options([1, 2, 3])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, [1, 2, 3])

    select_nth_option(live, 2)

    assert_selected(live, 2)
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

    assert_selected(live, :B, 2)
  end

  test "supports dropdown filled with values from map", %{conn: conn} do
    stub_options(%{A: 1, B: 2, C: 3})

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, :B, 2)
  end

  test "supports dropdown filled from an enumerable of maps", %{conn: conn} do
    stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, %{label: "C", value: 3}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, "B", 2)
  end

  test "supports dropdown filled from an enumerable of maps where only value is specified", %{
    conn: conn
  } do
    stub_options([%{value: "A"}, %{value: "B"}, %{value: "C"}])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, "B", "B")
  end

  test "supports dropdown filled from an enumerable of keywords only value is specified", %{
    conn: conn
  } do
    stub_options([[value: "A"], [value: "B"], [value: "C"]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, "B", "B")
  end

  test "supports dropdown filled from an enumerable of keywords", %{conn: conn} do
    stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, "B", 2)
  end

  test "supports dropdown filled with keywords with key as the label", %{conn: conn} do
    stub_options([[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_selected(live, "B", 2)
  end

  describe "after clicking on the text input field" do
    setup %{conn: conn} do
      stub_options(
        A: 1,
        B: 2,
        C: 3
      )

      {:ok, live, _html} =
        live(conn, "/?phx-focus=focus-event-for-parent&phx-blur=blur-event-for-parent")

      type(live, "ABC")

      select_nth_option(live, 2)

      assert_selected(live, :B, 2)

      element(live, selectors()[:text_input])
      |> render_click()

      %{live: live}
    end

    test "the text input field is cleared", %{live: live} do
      assert_clear(live, false)
    end

    test "hitting Escape restores the selection", %{live: live} do
      keydown(live, "Escape")

      assert_selected_static(live, :B, 2)
    end

    test "blurring the field restores the selection", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      assert_selected_static(live, :B, 2)
    end

    test "blurring, then clicking, then blurring again restores the selection", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      element(live, selectors()[:text_input])
      |> render_click()

      element(live, selectors()[:text_input])
      |> render_blur()

      assert_selected_static(live, :B, 2)
    end

    test "a focus event is sent to the parent", %{live: live} do
      assert_push_event(live, "select", %{
        id: "my_form_city_search_live_select_component",
        parent_event: "focus-event-for-parent"
      })
    end

    test "blurring the field sends a blur event to the parent", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      assert_push_event(live, "select", %{
        id: "my_form_city_search_live_select_component",
        parent_event: "blur-event-for-parent"
      })
    end

    test "when value forced, clicking & blurring restores the selection", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      send_update(live, value: 3)

      element(live, selectors()[:text_input])
      |> render_click()

      element(live, selectors()[:text_input])
      |> render_blur()

      assert_selected_static(live, :C, 3)
    end
  end

  describe "after focusing the text input field" do
    setup %{conn: conn} do
      stub_options(
        A: 1,
        B: 2,
        C: 3
      )

      {:ok, live, _html} =
        live(conn, "/?phx-focus=focus-event-for-parent&phx-blur=blur-event-for-parent")

      type(live, "ABC")

      select_nth_option(live, 2)

      assert_selected(live, :B, 2)

      element(live, selectors()[:text_input])
      |> render_focus()

      %{live: live}
    end

    test "the text input field is cleared", %{live: live} do
      assert_clear(live, false)
    end

    test "hitting Escape restores the selection", %{live: live} do
      keydown(live, "Escape")

      assert_selected_static(live, :B, 2)
    end

    test "blurring the field restores the selection", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      assert_selected_static(live, :B, 2)
    end

    test "blurring, then focusing, then blurring again restores the selection", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      element(live, selectors()[:text_input])
      |> render_focus()

      element(live, selectors()[:text_input])
      |> render_blur()

      assert_selected_static(live, :B, 2)
    end

    test "a focus event is sent to the parent", %{live: live} do
      assert_push_event(live, "select", %{
        id: "my_form_city_search_live_select_component",
        parent_event: "focus-event-for-parent"
      })
    end

    test "blurring the field sends a blur event to the parent", %{live: live} do
      element(live, selectors()[:text_input])
      |> render_blur()

      assert_push_event(live, "select", %{
        id: "my_form_city_search_live_select_component",
        parent_event: "blur-event-for-parent"
      })
    end
  end

  test "can navigate options with arrows", %{conn: conn} do
    stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/?style=daisyui")

    type(live, "ABC")

    navigate(live, 3, :down)
    navigate(live, 1, :up)

    assert_option_active(live, 2)
  end

  test "navigating up selects the last option", %{conn: conn} do
    stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/?style=daisyui")

    type(live, "ABC")

    navigate(live, 1, :up)

    assert_option_active(live, 3)
  end

  test "navigating down selects the first option", %{conn: conn} do
    stub_options([%{label: "A", value: 1}, %{label: "B", value: 2}, [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/?style=daisyui")

    type(live, "ABC")

    navigate(live, 1, :down)

    assert_option_active(live, 1)
  end

  test "dropdown becomes visible when typing", %{conn: conn} do
    stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert dropdown_visible(live)
  end

  describe "when the dropdown is visible" do
    setup %{conn: conn} do
      stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

      {:ok, live, _html} = live(conn, "/")

      type(live, "ABC")

      assert dropdown_visible(live)

      %{live: live}
    end

    test "blur on text input hides it", %{live: live} do
      render_blur(element(live, selectors()[:text_input]))

      refute dropdown_visible(live)
    end

    test "pressing the escape key hides it", %{live: live} do
      keydown(live, "Escape")

      refute dropdown_visible(live)
    end
  end

  describe "when the dropdown is hidden" do
    setup %{conn: conn} do
      stub_options([[label: "A", value: 1], [label: "B", value: 2], [label: "C", value: 3]])

      {:ok, live, _html} = live(conn, "/")

      type(live, "ABC")

      render_blur(element(live, selectors()[:text_input]))

      refute dropdown_visible(live)

      %{live: live}
    end

    test "focus on text input shows it", %{live: live} do
      render_focus(element(live, selectors()[:text_input]))

      assert dropdown_visible(live)
    end

    test "click on text input shows it", %{live: live} do
      render_click(element(live, selectors()[:text_input]))

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

  test "can clear the selection", %{conn: conn} do
    stub_options(
      A: 1,
      B: 2,
      C: 3
    )

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_selected(live, :B, 2)

    send_update(live, value: nil)

    assert_clear(live)
  end

  test "can force the selection", %{conn: conn} do
    stub_options(
      A: 1,
      B: 2,
      C: 3
    )

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_selected(live, :B, 2)

    send_update(live, value: 3)

    assert_selected(live, :C, 3)
  end

  test "can force selection and options simultaneously", %{conn: conn} do
    stub_options(
      A: 1,
      B: 2,
      C: 3
    )

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_selected(live, :B, 2)

    send_update(live, value: 4, options: [C: 3, D: 4])

    assert_selected(live, :D, 4)
  end

  test "renders custom :option slots", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/live_component_test")

    type(live, "Ber",
      component: "#my_form_city_search_live_select_component",
      parent: "#form_component"
    )

    options =
      render(live)
      |> Floki.find("#{selectors()[:dropdown]} > li")

    assert length(options) > 0

    for option <- options do
      assert Floki.text(option) =~ "with custom slot"
    end
  end

  test "renders custom :tag slots", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/live_component_test")

    type(live, "Ber",
      component: "#my_form_city_search_live_select_component",
      parent: "#form_component"
    )

    options =
      render(live)
      |> Floki.find("#{selectors()[:dropdown]} > li")

    assert length(options) > 0

    select_nth_option(live, 1,
      method: :click,
      component: "#my_form_city_search_live_select_component"
    )

    tag =
      render(live)
      |> Floki.find("#{selectors()[:tags_container]} > div")
      |> Floki.text()

    assert tag =~ "with custom slot"
  end

  test "selection can be cleared from the form", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    render_change(live, "change", %{"my_form" => %{"city_search" => ""}})

    assert_clear_static(live)
  end

  test "selection recovery (1)", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    value = [10, 20]

    render_change(live, "change", %{
      "my_form" => %{"city_search" => Phoenix.json_library().encode!(value)}
    })

    render_hook(element(live, selectors()[:container]), "selection_recovery", [
      %{label: "A", value: value}
    ])

    assert_selected_static(live, "A", value)
  end

  test "selection recovery (2)", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    value = %{"name" => "A", "pos" => [10.0, 20.0]}

    render_change(live, "change", %{
      "my_form" => %{"city_search" => Phoenix.json_library().encode!(value)}
    })

    render_hook(element(live, selectors()[:container]), "selection_recovery", [
      %{label: "A", value: value}
    ])

    assert_selected_static(live, "A", value)
  end

  test "selection recovery (3)", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/")

    value = "A"

    render_change(live, "change", %{
      "my_form" => %{"city_search" => Phoenix.json_library().encode!(value)}
    })

    render_hook(element(live, selectors()[:container]), "selection_recovery", [
      %{label: "A", value: value}
    ])

    assert_selected_static(live, "A", value)
  end

  for style <- [:daisyui, :tailwind, :none, nil] do
    @style style

    describe "when style = #{@style || "default"}" do
      test "class for active option is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        navigate(live, 1, :down)

        assert_option_active(
          live,
          1,
          get_in(expected_class(), [@style || default_style(), :active_option]) || ""
        )
      end

      test "class for active option can be overridden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&active_option_class=foo")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        navigate(live, 1, :down)

        assert_option_active(
          live,
          1,
          "foo"
        )
      end

      test "class for selected option is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        select_nth_option(live, 2)

        type(live, "ABC")

        assert_selected_option_class(
          live,
          2,
          get_in(expected_class(), [@style || default_style(), :selected_option]) || []
        )
      end

      test "class for selected option can be overridden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&selected_option_class=foo")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        select_nth_option(live, 2)

        type(live, "ABC")

        assert_selected_option_class(
          live,
          2,
          ~W(foo)
        )
      end

      test "class for available option is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        select_nth_option(live, 2)

        type(live, "ABC")

        assert_available_option_class(
          live,
          2,
          get_in(expected_class(), [@style || default_style(), :available_option]) || []
        )
      end

      test "class for available option can be overridden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&available_option_class=foo")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        select_nth_option(live, 2)

        type(live, "ABC")

        assert_available_option_class(
          live,
          2,
          ~W(foo)
        )
      end

      test "class for unavailable option is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&mode=tags&max_selectable=1")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        select_nth_option(live, 2)

        type(live, "ABC")

        assert_unavailable_option_class(
          live,
          2,
          get_in(expected_class(), [@style || default_style(), :unavailable_option]) || []
        )
      end

      test "class for unavailable option can be overridden", %{conn: conn} do
        {:ok, live, _html} =
          live(conn, "/?style=#{@style}&mode=tags&max_selectable=1&unavailable_option_class=foo")

        stub_options(["A", "B", "C"])

        type(live, "ABC")

        select_nth_option(live, 2)

        type(live, "ABC")

        assert_unavailable_option_class(
          live,
          2,
          ~W(foo)
        )
      end
    end
  end

  describe "with disabled option" do
    test "disabled options are skipped when navigating down with keyboard", %{conn: conn} do
      stub_options([{"A", 1, false}, {"B", 2, true}, {"C", 3, false}])

      {:ok, live, _html} = live(conn, "/")

      type(live, "ABC")
      assert_options(live, ["A", "B", "C"])

      select_nth_option(live, 2)
      assert_selected(live, "C", 3)
    end

    test "disabled options are skipped when navigating up with keyboard", %{conn: conn} do
      stub_options([{"A", 1, false}, {"B", 2, true}, {"C", 3, false}])

      {:ok, live, _html} = live(conn, "/")

      type(live, "ABC")
      assert_options(live, ["A", "B", "C"])

      # Navigate to C by going two down
      navigate(live, 2, :down)

      # Navigate back to A by going 1 up as we skip B because it's disabled.
      # Then select the item we're on. It should be "A"
      navigate(live, 1, :up)
      keydown(live, "Enter")

      assert_selected(live, "A", 1)
    end

    test "options can be disabled when passed as enumerable of maps", %{conn: conn} do
      stub_options([
        %{label: "A", value: 1, disabled: false},
        %{label: "B", value: 2, disabled: true},
        %{label: "C", value: 3, disabled: false}
      ])

      {:ok, live, _html} = live(conn, "/")

      type(live, "ABC")
      assert_options(live, ["A", "B", "C"])

      select_nth_option(live, 1)
      assert_selected(live, "A", 1)

      type(live, "ABC")
      assert_options(live, ["A", "B", "C"])
      # The maps are sorted on their key value pairings on the showcase page
      # before being sent to the LiveSelect component. This results in the
      # disabled option "B" being sorted last.
      select_nth_option(live, 3, method: :click)
      assert_selected_static(live, "A", 1)
    end

    test "disabled options can't be selected with mouseclick", %{conn: conn} do
      stub_options([{"A", 1, false}, {"B", 2, true}, {"C", 3, false}])

      {:ok, live, _html} = live(conn, "/")
      type(live, "ABC")

      assert_options(live, ["A", "B", "C"])
      select_nth_option(live, 1)
      assert_selected(live, "A", 1)

      # Mouse clicks won't change the selected option
      type(live, "ABC")
      select_nth_option(live, 2, method: :click)
      assert_selected_static(live, "A", 1)
    end
  end
end
