defmodule LiveSelect.TestHelpers do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect

  @selectors [
    container: "div[name=live-select]",
    text_input: "input#my_form_city_search_text_input",
    dropdown: "ul[name=live-select-dropdown]",
    dropdown_entries: "ul[name=live-select-dropdown] > li > div",
    hidden_input: "input#my_form_city_search",
    tag: "div[name=tags-container] > div"
  ]

  def select_nth_option(live, n, method \\ :key) do
    case method do
      :key ->
        navigate(live, n, :down)
        keydown(live, "Enter")

      :click ->
        if has_element?(live, "li > div[data-idx=#{n - 1}]") do
          element(live, @selectors[:container])
          |> render_hook("option_click", %{"idx" => to_string(n - 1)})
        end
    end
  end

  def unselect_nth_option(live, n) do
    element(live, "div[name=tags-container] button[phx-value-idx=#{n - 1}][phx-click]")
    |> render_click()
  end

  def keydown(live, key) do
    element(live, @selectors[:container])
    |> render_hook("keydown", %{"key" => key})
  end

  def dropdown_visible(live) do
    invisible =
      element(live, @selectors[:dropdown])
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("style")
      |> List.first() =~ "display: none;"

    !invisible
  end

  def stub_options(options) do
    Mox.stub(LiveSelect.MessageHandlerMock, :handle, fn change_msg, _ ->
      update_options(
        change_msg,
        options
      )
    end)

    :ok
  end

  def assert_option_size(live, size) when is_integer(size) do
    assert_option_size(live, &(&1 == size))
  end

  def assert_option_size(live, fun) when is_function(fun, 1) do
    assert render(live)
           |> Floki.parse_document!()
           |> Floki.find(@selectors[:dropdown_entries])
           |> Enum.count()
           |> then(&fun.(&1))
  end

  def type(live, text) do
    0..String.length(text)
    |> Enum.each(fn pos ->
      element(live, @selectors[:text_input])
      |> render_keyup(%{"key" => String.at(text, pos), "value" => String.slice(text, 0..pos)})
    end)
  end

  def assert_options(rendered, elements) when is_binary(rendered) do
    assert rendered
           |> Floki.parse_document!()
           |> Floki.find(@selectors[:dropdown_entries])
           |> Floki.text()
           |> String.replace(~r/\s+/, "") ==
             Enum.join(elements)
  end

  def assert_options(live, elements), do: assert_options(render(live), elements)

  def assert_option_active(live, pos, active_class \\ "active")

  def assert_option_active(_live, _pos, "") do
    assert true
  end

  def assert_option_active(live, pos, active_class) do
    element_classes =
      render(live)
      |> Floki.parse_document!()
      |> Floki.attribute(@selectors[:dropdown_entries], "class")
      |> Enum.map(&String.trim/1)

    for {element_class, idx} <- Enum.with_index(element_classes, 1) do
      if idx == pos do
        assert String.contains?(element_class, active_class)
      else
        refute String.contains?(element_class, active_class)
      end
    end
  end

  def assert_selected(live, label, value \\ nil) do
    value = if value, do: value, else: label

    hidden_input =
      live
      |> element(@selectors[:hidden_input])
      |> render()
      |> Floki.parse_fragment!()

    assert hidden_input
           |> Floki.attribute("value") ==
             [to_string(value)]

    text_input =
      live
      |> element(@selectors[:text_input])
      |> render()
      |> Floki.parse_fragment!()

    assert text_input
           |> Floki.attribute("readonly") ==
             ["readonly"]

    assert_push_event(live, "select", %{
      id: "my_form_city_search_component",
      selection: [%{label: ^label, value: ^value}]
    })
  end

  def assert_selected_static(html, label, value \\ nil) do
    value = if value, do: value, else: label

    assert Floki.attribute(html, @selectors[:hidden_input], "value") == [encode_value(value)]

    text_input = Floki.find(html, @selectors[:text_input])

    assert Floki.attribute(text_input, "readonly") ==
             ["readonly"]

    assert Floki.attribute(text_input, "value") ==
             [label]
  end

  def assert_selected_multiple_static(live, values) do
    assert_selected_multiple_static(live, values, values)
  end

  def assert_selected_multiple_static(html, values, tag_labels) when is_binary(html) do
    assert Floki.attribute(html, "#{@selectors[:container]} input[type=hidden]", "value") ==
             encode_values(values)

    assert html
           |> Floki.find(@selectors[:tag])
           |> Floki.text(sep: ",")
           |> String.split(",")
           |> Enum.map(&String.trim/1) ==
             tag_labels
  end

  def assert_selected_multiple_static(live, values, tag_labels) do
    assert_selected_multiple_static(render(live), values, tag_labels)
  end

  def assert_selected_multiple(live, values) do
    assert_selected_multiple(live, values, values, values)
  end

  def assert_selected_multiple(live, values, labels) do
    assert_selected_multiple(live, values, labels, labels)
  end

  def assert_selected_multiple(live, values, labels, tag_labels) do
    assert_selected_multiple_static(live, values, tag_labels)

    selection =
      Enum.zip([labels, tag_labels, values])
      |> Enum.map(fn
        {tag, tag_label, value} when tag_label == tag -> %{label: tag, value: value}
        {tag, tag_label, value} -> %{label: tag, tag_label: tag_label, value: value}
      end)

    assert_push_event(live, "select", %{
      id: "my_form_city_search_component",
      selection: ^selection
    })
  end

  def assert_reset(live, default_value \\ nil) do
    assert live
           |> element(@selectors[:text_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("readonly") ==
             []

    assert live
           |> element(@selectors[:hidden_input])
           |> render()
           |> Floki.parse_fragment!()
           |> Floki.attribute("value") == List.wrap(default_value)

    assert_push_event(live, "reset", %{
      id: "my_form_city_search_component"
    })
  end

  def navigate(live, n, dir) do
    key =
      case dir do
        :down -> "ArrowDown"
        :up -> "ArrowUp"
      end

    for _ <- 1..n do
      keydown(live, key)
    end
  end

  defp encode_values(values) when is_list(values) do
    for value <- values, do: encode_value(value)
  end

  defp encode_value(value) when is_atom(value) or is_binary(value) or is_number(value), do: value

  defp encode_value(value), do: Jason.encode!(value)
end
