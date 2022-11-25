defmodule LiveSelectTagsTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect.TestHelpers

  setup %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?mode=tags")

    %{live: live}
  end

  test "can select multiple options", %{live: live} do
    stub_options(["A", "B", "C", "D"])

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_options_selected(live, ["B"])

    type(live, "ABC")

    select_nth_option(live, 3)

    assert_options_selected(live, ["B", "D"])
  end

  @tag :skip
  test "selected options appear in tags"

  test "selected options don't reappear in the dropdown", %{live: live} do
    stub_options(["A", "B", "C", "D"])

    type(live, "ABC")

    assert_options(live, ["A", "B", "C", "D"])

    select_nth_option(live, 2)

    type(live, "ABC")

    assert_options(live, ["A", "C", "D"])

    select_nth_option(live, 2)

    type(live, "ABC")

    assert_options(live, ["A", "D"])
  end

  @tag :skip
  test "can remove selected options by clicking on tag"

  @tag :skip
  test "can style tags"

  @tag :skip
  test "can specify an alternative label for tags"
end
