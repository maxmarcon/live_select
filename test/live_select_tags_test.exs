defmodule LiveSelectTagsTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect.TestHelpers

  @selectors [
    option_container: "ul[name=live-select-dropdown] > li"
  ]

  @default_style :tailwind
  @expected_class [
    daisyui: [
      selected_option: ~S(disabled)
    ],
    tailwind: [
      selected_option: ~S(text-gray-400)
    ]
  ]

  @override_class_option [
    selected_option: :selected_option_class
  ]

  setup %{conn: conn} do
    {:ok, live, _html} = live(conn, "/?mode=tags")

    %{live: live}
  end

  test "can select multiple options", %{live: live} do
    stub_options(["A", "B", "C", "D"])

    type(live, "ABC")

    select_nth_option(live, 2)

    type(live, "ABC")

    select_nth_option(live, 3)

    assert_selected_multiple(live, ["B", "C"])
  end

  @tag :skip
  test "selected options appear in tags"

  @tag :skip
  test "already selected options are not selectable in the dropdown"

  @tag :skip
  test "can remove selected options by clicking on tag"

  @tag :skip
  test "can style tags"

  @tag :skip
  test "can specify an alternative label for tags"

  for style <- [:daisyui, :tailwind, :none, nil] do
    @style style
    describe "when style = #{@style || "default"}" do
      test "class for selected option is set", %{conn: conn} do
        {:ok, live, _} = live(conn, "/?mode=tags&style=#{@style}")

        :ok = select_and_open_dropdown(live, 2)

        assert_option_container_class(
          live,
          2,
          get_in(@expected_class, [@style || @default_style, :selected_option]) || ""
        )
      end

      test "class for selected option can be overridden", %{conn: conn} do
        {:ok, live, _} = live(conn, "/?mode=tags&style=#{@style}&selected_option_class=foo")

        :ok = select_and_open_dropdown(live, 2)

        assert_option_container_class(
          live,
          2,
          "foo"
        )
      end
    end
  end

  defp select_and_open_dropdown(live, pos) do
    if pos < 1 || pos > 4, do: raise("pos must be between 1 adn 4")

    stub_options(["A", "B", "C", "D"])

    type(live, "ABC")

    select_nth_option(live, 2)

    type(live, "ABC")

    :ok
  end

  defp assert_option_container_class(_live, _selected_pos, ""), do: true

  defp assert_option_container_class(live, selected_pos, selected_class) do
    element_classes =
      render(live)
      |> Floki.parse_document!()
      |> Floki.attribute(@selectors[:option_container], "class")
      |> Enum.map(&String.trim/1)

    for {element_class, idx} <- Enum.with_index(element_classes, 1) do
      if idx == selected_pos do
        assert String.contains?(element_class, selected_class)
      else
        refute String.contains?(element_class, selected_class)
      end
    end
  end
end
