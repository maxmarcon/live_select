defmodule LiveSelectTagsTest do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect.TestHelpers

  @selectors [
    option: "ul[name=live-select-dropdown] > li",
    tags_container: "div[name=tags-container]",
    tag: "div[name=tags-container] > div"
  ]

  @default_style :tailwind
  @expected_class [
    daisyui: [
      selected_option: ~S(disabled),
      tags_container: ~S(flex flex-wrap gap-1 p-1 rounded-md bg-primary-content),
      tag: ~S(p-1.5 text-sm badge badge-primary)
    ],
    tailwind: [
      selected_option: ~S(text-gray-400),
      tags_container: ~S(flex flex-wrap bg-white rounded-md gap-1 p-1),
      tag: ~S(p-1 text-sm rounded-lg bg-blue-400 flex)
    ]
  ]

  @override_class_option [
    selected_option: :selected_option_class,
    tag: :tag_class,
    tags_container: :tags_container_class
  ]

  @extend_class_option [
    tag: :tag_extra_class,
    tags_container: :tags_container_extra_class
  ]

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

    assert_selected_multiple(live, ~w(B))
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

    assert_selected_multiple(live, ["Rome", "New York"], ["R", "NY"])
  end

  test "can specify alternative labels for tags using keywords", %{live: live} do
    stub_options([[tag_label: "R", value: "Rome"], [tag_label: "NY", value: "New York"]])

    type(live, "ABC")

    select_nth_option(live, 1)

    type(live, "ABC")

    select_nth_option(live, 2)

    assert_selected_multiple(live, ["Rome", "New York"], ["R", "NY"])
  end

  for style <- [:daisyui, :tailwind, :none, nil] do
    @style style
    describe "when style = #{@style || "default"}" do
      test "class for selected option is set", %{conn: conn} do
        {:ok, live, _} = live(conn, "/?mode=tags&style=#{@style}")

        :ok = select_and_open_dropdown(live, 2)

        assert_selected_option_class(
          live,
          2,
          get_in(@expected_class, [@style || @default_style, :selected_option]) || ""
        )
      end

      test "class for selected option can be overridden", %{conn: conn} do
        {:ok, live, _} = live(conn, "/?mode=tags&style=#{@style}&selected_option_class=foo")

        :ok = select_and_open_dropdown(live, 2)

        assert_selected_option_class(
          live,
          2,
          "foo"
        )
      end

      for element <- [
            :tags_container,
            :tag
          ] do
        @element element

        test "#{@element} has default class", %{conn: conn} do
          {:ok, live, _html} = live(conn, "/?mode=tags&style=#{@style}")

          :ok = select_and_open_dropdown(live, 2)

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

            {:ok, live, _html} = live(conn, "/?mode=tags&style=#{@style}&#{option}=foo")

            :ok = select_and_open_dropdown(live, 2)

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

            {:ok, live, _html} = live(conn, "/?mode=tags&style=#{@style}&#{option}=foo")

            :ok = select_and_open_dropdown(live, 2)

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

              {:ok, live, _html} =
                live(conn, "/?mode=tags&style=#{@style}&#{option}=!#{class_to_remove}")

              :ok = select_and_open_dropdown(live, 2)

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
    end
  end

  defp select_and_open_dropdown(live, pos) do
    if pos < 1 || pos > 4, do: raise("pos must be between 1 adn 4")

    stub_options(~w(A B C D))

    type(live, "ABC")

    select_nth_option(live, 2)

    type(live, "ABC")

    :ok
  end

  defp assert_selected_option_class(_live, _selected_pos, ""), do: true

  defp assert_selected_option_class(live, selected_pos, selected_class) do
    element_classes =
      render(live)
      |> Floki.parse_document!()
      |> Floki.attribute(@selectors[:option], "class")
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
