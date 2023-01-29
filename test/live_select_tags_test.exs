defmodule LiveSelectTagsTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect.TestHelpers

  setup %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?mode=tags")

    %{live: live}
  end

  test "can select multiple options", %{live: live} do
    stub_options(~w(A B C D))

    type(live, "ABC")

    select_nth_option(live, 2, :key)

    type(live, "ABC")

    select_nth_option(live, 4, :click)

    assert_selected_multiple(live, ~w(B D))
  end

  test "already selected options are not selectable in the dropdown using keyboard", %{live: live} do
    stub_options(~w(A B C D))

    type(live, "ABC")

    select_nth_option(live, 2)

    type(live, "ABC")
    navigate(live, 2, :down)
    keydown(live, "Enter")

    assert_selected_multiple(live, ~w(B C))

    type(live, "ABC")
    navigate(live, 10, :down)
    navigate(live, 10, :up)
    keydown(live, "Enter")

    assert_selected_multiple(live, ~w(B C A))
  end

  test "already selected options are not selectable in the dropdown using mouse", %{live: live} do
    select_and_open_dropdown(live, 2)

    assert_selected_multiple(live, ~w(B))

    select_nth_option(live, 2, :click)

    assert_selected_multiple_static(live, ~w(B))
  end

  test "hitting enter with only one option selects it", %{live: live} do
    stub_options(~w(A))

    type(live, "ABC")

    keydown(live, "Enter")

    assert_selected_multiple(live, ~w(A))
  end

  test "hitting enter with more than one option does not select", %{live: live} do
    stub_options(~w(A B))

    type(live, "ABC")

    keydown(live, "Enter")

    assert_selected_multiple_static(live, [])
  end

  test "hitting enter with only one option does not select it if already selected", %{live: live} do
    stub_options(~w(A))

    type(live, "ABC")

    select_nth_option(live, 1)

    assert_selected_multiple(live, ~w(A))

    type(live, "ABC")

    keydown(live, "Enter")

    assert_selected_multiple_static(live, ~w(A))
  end

  describe "when user_defined_options = true" do
    setup %{conn: conn} do
      {:ok, live, _html} = live(conn, "/?mode=tags&user_defined_options=true")
      %{live: live}
    end

    test "hitting enter adds entered text to selection", %{live: live} do
      stub_options(["A", "B"])

      type(live, "ABC")

      keydown(live, "Enter")

      assert_selected_multiple(live, ["ABC"])
    end

    test "hitting enter does not add text to selection if element with same label is already selected",
         %{live: live} do
      stub_options(["ABC", "DEF"])

      type(live, "ABC")

      select_nth_option(live, 1, :key)

      assert_selected_multiple(live, ["ABC"])

      type(live, "ABC")

      assert_options(live, ["ABC", "DEF"])

      keydown(live, "Enter")

      assert_selected_multiple_static(live, ["ABC"])
    end

    test "hitting enter adds text to selection even if there is only one available option", %{
      live: live
    } do
      stub_options(["A"])

      type(live, "ABC")

      keydown(live, "Enter")

      assert_selected_multiple(live, ["ABC"])
    end

    test "text added to selection should be trimmed", %{live: live} do
      stub_options([])

      type(live, "  ABC ")

      keydown(live, "Enter")

      assert_selected_multiple_static(live, ["ABC"])
    end

    test "text with only whitespace is ignored and not added to selection", %{live: live} do
      stub_options(["ABC"])

      type(live, "    ")

      keydown(live, "Enter")

      assert_selected_multiple_static(live, [])
    end

    test "text shorter than update_min_len is ignored and not added to selection", %{live: live} do
      stub_options([{"ABC", 1}, {"DEF", 2}])

      type(live, "AB")

      keydown(live, "Enter")

      assert_selected_multiple_static(live, [])
    end

    test "hitting enter while options are awaiting update does not select", %{live: live} do
      stub_options(~w(A B C), delay_forever: true)

      type(live, "ABC")

      keydown(live, "Enter")

      assert_selected_multiple_static(live, [])
    end

    test "one can still select options from the dropdown", %{live: live} do
      stub_options(~w(A B C))

      type(live, "ABC")

      select_nth_option(live, 1, :key)

      type(live, "ABC")

      select_nth_option(live, 2, :click)

      assert_selected_multiple(live, ~w(A B))
    end
  end

  describe "when max_selectable option is set" do
    setup %{conn: conn} do
      {:ok, live, _html} = live(conn, "/?mode=tags&max_selectable=2")

      %{live: live}
    end

    test "prevents selection of more than max_selectable options", %{live: live} do
      stub_options(~w(A B C D))

      type(live, "ABC")

      select_nth_option(live, 2, :key)

      type(live, "ABC")

      select_nth_option(live, 4, :click)

      assert_selected_multiple(live, ~w(B D))

      type(live, "ABC")

      select_nth_option(live, 3, :click)

      assert_selected_multiple_static(live, ~w(B D))
    end
  end

  test "can remove selected options by clicking on tag", %{live: live} do
    stub_options(~w(A B C D))

    type(live, "ABC")

    select_nth_option(live, 2)

    type(live, "ABC")

    select_nth_option(live, 3)

    type(live, "ABC")

    select_nth_option(live, 1)

    assert_selected_multiple(live, ~w(B D A))

    unselect_nth_option(live, 2)

    assert_selected_multiple(live, ~w(B A))
  end

  test "can specify alternative labels for tags using maps", %{live: live} do
    stub_options([%{tag_label: "R", value: "Rome"}, %{tag_label: "NY", value: "New York"}])

    type(live, "ABC")

    select_nth_option(live, 1)

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_selected_multiple(live, [
      %{label: "Rome", value: "Rome", tag_label: "R"},
      %{label: "New York", value: "New York", tag_label: "NY"}
    ])
  end

  test "can specify alternative labels for tags using keywords", %{live: live} do
    stub_options([[tag_label: "R", value: "Rome"], [tag_label: "NY", value: "New York"]])

    type(live, "ABC")

    select_nth_option(live, 1)

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_selected_multiple(live, [
      %{label: "Rome", value: "Rome", tag_label: "R"},
      %{label: "New York", value: "New York", tag_label: "NY"}
    ])
  end

  test "can be disabled", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?disabled=true&mode=tags")

    assert element(live, selectors()[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("disabled") == ["disabled"]
  end

  test "can clear the selection", %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?mode=tags")

    stub_options(~w(A B C D))

    type(live, "ABC")

    select_nth_option(live, 1)

    type(live, "ABC")

    select_nth_option(live, 2, :click)

    assert_selected_multiple(live, ~w(A B))

    render_click(live, "clear-selection", %{})

    assert_selected_multiple(live, [])
  end

  defp select_and_open_dropdown(live, pos) do
    if pos < 1 || pos > 4, do: raise("pos must be between 1 and 4")

    stub_options(~w(A B C D))

    type(live, "ABC")

    select_nth_option(live, 2)

    type(live, "ABC")

    :ok
  end
end
