defmodule LiveSelect.TestHelpers do
  @moduledoc false

  use LiveSelectWeb.ConnCase, async: true

  import LiveSelect

  @selectors [
    container: "div[name=live-select]",
    text_input: "input#my_form_city_search_text_input[type=text]",
    dropdown: "ul[name=live-select-dropdown]",
    dropdown_entries: "ul[name=live-select-dropdown] > li > div",
    option: "ul[name=live-select-dropdown] > li:first-of-type > div",
    hidden_input: "input#my_form_city_search[type=hidden]"
  ]

  def select_nth_option(live, n, method \\ :key) do
    case method do
      :key ->
        navigate(live, n, :down)
        keydown(live, "Enter")

      :click ->
        element(live, "li[phx-value-idx=#{n - 1}")
        |> render_click()
    end
  end

  def keydown(live, key) do
    element(live, @selectors[:container])
    |> render_hook("keydown", %{"key" => key})
  end

  def dropdown_mouseover(live) do
    element(live, @selectors[:container])
    |> render_hook("dropdown-mouseover")
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

  def assert_options(live, elements) do
    assert render(live)
           |> Floki.parse_document!()
           |> Floki.find(@selectors[:dropdown_entries])
           |> Floki.text()
           |> String.replace(~r/\s+/, "") ==
             Enum.join(elements)
  end

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

    for {element_class, idx} <- Enum.with_index(element_classes) do
      if idx == pos do
        assert String.contains?(element_class, active_class)
      else
        refute String.contains?(element_class, active_class)
      end
    end
  end

  def assert_option_selected(live, label, value \\ nil) do
    # would be nice to check the value of the hidden input field, but this
    # is set by the JS hook
    value = if value, do: value, else: label

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

  def assert_reset(live, default_value \\ nil) do
    text_input =
      live
      |> element(@selectors[:text_input])
      |> render()
      |> Floki.parse_fragment!()

    assert text_input
           |> Floki.attribute("readonly") ==
             []

    assert_push_event(live, "reset", %{
      id: "my_form_city_search_component",
      default_value: ^default_value
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
end
