defmodule LiveSelectTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase

  import LiveSelect
  import Mox

  alias LiveSelect.ChangeMsg

  @expected_class [
    daisyui: [
      container: ~S(dropdown),
      text_input: ~S(input input-bordered),
      text_input_selected: ~S(input-primary text-primary),
      dropdown: ~S(dropdown-content menu menu-compact shadow rounded-box),
      active_option: ~S(active)
    ]
  ]

  @override_class_option [
    container: :container_class,
    text_input: :text_input_class,
    dropdown: :dropdown_class
  ]

  @extend_class_option [
    container: :container_extra_class,
    text_input: :text_input_extra_class,
    dropdown: :dropdown_extra_class
  ]

  @selectors [
    container: "div[name=live-select]",
    text_input: "input#my_form_city_search_text_input[type=text]",
    dropdown: "ul[name=live-select-dropdown]",
    dropdown_entries: "ul[name=live-select-dropdown] > li > span"
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
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(change_msg, ["A", "B", "C"])
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "Ber")

    assert_option_size(live, &(&1 > 0))
  end

  test "number of minimum keystrokes can be configured", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(change_msg, ["A", "B", "C"])
    end)

    {:ok, live, _html} = live(conn, "/?search_term_min_length=4")

    type(live, "Ber")

    assert_option_size(live, 0)

    type(live, "Berl")

    assert_option_size(live, &(&1 > 0))
  end

  test "supports dropdown filled with tuples", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [{"A", 1}, {"B", 2}, {"C", 3}]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "can select option with mouseclick", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [{"A", 1}, {"B", 2}, {"C", 3}]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2, :click)

    assert_option_selected(live, "B", 2)
  end

  test "supports dropdown filled with strings", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        ["A", "B", "C"]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B")
  end

  test "supports dropdown filled with atoms", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [:A, :B, :C]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, :B)
  end

  test "supports dropdown filled with integers", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [1, 2, 3]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, [1, 2, 3])

    select_nth_option(live, 2)

    assert_option_selected(live, 2)
  end

  test "supports dropdown filled with keywords", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, "B", 2)
  end

  test "supports dropdown filled with values from keyword list", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        A: 1,
        B: 2,
        C: 3
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, :B, 2)
  end

  test "supports dropdown filled with values from map", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        %{A: 1, B: 2, C: 3}
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    assert_options(live, ["A", "B", "C"])

    select_nth_option(live, 2)

    assert_option_selected(live, :B, 2)
  end

  test "can navigate options with arrows", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    navigate(live, 4, :down)
    navigate(live, 1, :up)

    assert_option_active(live, 1)
  end

  test "moving the mouse on the dropdown deactivate option", %{conn: conn} do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
      )
    end)

    {:ok, live, _html} = live(conn, "/")

    type(live, "ABC")

    navigate(live, 1, :down)

    assert_option_active(live, 0)

    dropdown_mouseover(live)

    assert_option_active(live, -1)
  end

  test "can be disabled", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?disabled=true")

    assert element(live, @selectors[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("disabled") == ["true"]
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

  for style <- [:daisyui, :none, nil] do
    @style style

    describe "when style = #{@style || "default"}" do
      for element <- [
            :container,
            :text_input,
            :dropdown
          ] do
        @element element

        test "#{@element} has default class", %{conn: conn} do
          {:ok, live, _html} = live(conn, "/?style=#{@style}")

          assert element(live, @selectors[@element])
                 |> render()
                 |> Floki.parse_fragment!()
                 |> Floki.attribute("class") == [
                   get_in(@expected_class, [@style || :daisyui, @element]) || ""
                 ]
        end

        if @override_class_option[@element] do
          test "#{@element} class can be overridden with #{@override_class_option[@element]}", %{
            conn: conn
          } do
            option = @override_class_option[@element]

            {:ok, live, _html} = live(conn, "/?style=#{@style}&#{option}=foo")

            assert element(live, @selectors[@element])
                   |> render()
                   |> Floki.parse_fragment!()
                   |> Floki.attribute("class") == [
                     "foo"
                   ]
          end
        end

        if @extend_class_option[@element] do
          test "#{@element} class can be extended with #{@extend_class_option[@element]}", %{
            conn: conn
          } do
            option = @extend_class_option[@element]

            {:ok, live, _html} = live(conn, "/?style=#{@style}&#{option}=foo")

            assert element(live, @selectors[@element])
                   |> render()
                   |> Floki.parse_fragment!()
                   |> Floki.attribute("class") == [
                     (get_in(@expected_class, [@style || :daisyui, @element]) || "") <> " foo"
                   ]
          end
        end
      end

      test "class for active option is set", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}")

        Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
          update_options(
            change_msg,
            [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
          )
        end)

        type(live, "ABC")

        navigate(live, 1, :down)

        assert_option_active(
          live,
          0,
          get_in(@expected_class, [@style || :daisyui, :active_option]) || ""
        )
      end

      test "class for active option can be overriden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&active_option_class=foo")

        Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
          update_options(
            change_msg,
            [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
          )
        end)

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

        Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
          update_options(
            change_msg,
            [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
          )
        end)

        type(live, "ABC")

        select_nth_option(live, 1)

        expected_class =
          (get_in(@expected_class, [@style || :daisyui, :text_input]) || "") <>
            " " <>
            (get_in(@expected_class, [@style || :daisyui, :text_input_selected]) || "")

        assert element(live, @selectors[:text_input])
               |> render()
               |> Floki.parse_fragment!()
               |> Floki.attribute("class") == [
                 expected_class
               ]
      end

      test "additional class for text input selected can be overridden", %{conn: conn} do
        {:ok, live, _html} = live(conn, "/?style=#{@style}&text_input_selected_class=foo")

        Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
          update_options(
            change_msg,
            [[key: "A", value: 1], [key: "B", value: 2], [key: "C", value: 3]]
          )
        end)

        type(live, "ABC")

        select_nth_option(live, 1)

        expected_class =
          (get_in(@expected_class, [@style || :daisyui, :text_input]) || "") <>
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

  defp assert_option_size(live, size) when is_integer(size) do
    assert_option_size(live, &(&1 == size))
  end

  defp assert_option_size(live, fun) when is_function(fun, 1) do
    render(live)

    assert render(live)
           |> Floki.parse_document!()
           |> Floki.find(@selectors[:dropdown_entries])
           |> Enum.count()
           |> then(&fun.(&1))
  end

  defp type(live, text) do
    0..String.length(text)
    |> Enum.each(fn pos ->
      element(live, @selectors[:text_input])
      |> render_keyup(%{"key" => String.at(text, pos), "value" => String.slice(text, 0..pos)})
    end)
  end

  defp assert_options(live, elements) do
    assert render(live)
           |> Floki.parse_document!()
           |> Floki.find(@selectors[:dropdown_entries])
           |> Floki.text()
           |> String.replace(~r/\s+/, "") ==
             Enum.join(elements)
  end

  defp assert_option_active(live, pos, active_class \\ "active") do
    attributes =
      render(live)
      |> Floki.parse_document!()
      |> Floki.attribute(@selectors[:dropdown_entries], "class")
      |> Enum.map(&String.trim/1)

    expected_attributes =
      0..(Enum.count(attributes) - 1)
      |> Enum.map(&if &1 == pos, do: active_class, else: "")

    assert attributes == expected_attributes
  end

  defp assert_option_selected(live, label, value \\ nil) do
    # would be nice to check the value of the hidden input field, but this
    # is set by the JS hook
    assert live
           |> element(@selectors[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("value") ==
             [to_string(label)]

    value = if value, do: value, else: label

    assert_push_event(live, "selected", %{selected: [^label, ^value]})
  end

  defp navigate(live, n, dir) do
    key =
      case dir do
        :down -> "ArrowDown"
        :up -> "ArrowUp"
      end

    for _ <- 1..n do
      keydown(live, key)
    end
  end

  defp select_nth_option(live, n, method \\ :key) do
    case method do
      :key ->
        navigate(live, n, :down)
        keydown(live, "Enter")

      :click ->
        element(live, "li[name=option-#{n}")
        |> render_click()
    end
  end

  defp keydown(live, key) do
    element(live, @selectors[:container])
    |> render_hook("keydown", %{"key" => key})
  end

  defp dropdown_mouseover(live) do
    element(live, @selectors[:container])
    |> render_hook("dropdown-mouseover")
  end
end
