# LiveSelect 

[![Hex.pm](https://img.shields.io/hexpm/v/live_select.svg)](https://hex.pm/packages/live_select)
[![Elixir CI](https://github.com/maxmarcon/live_select/actions/workflows/elixir.yml/badge.svg)](https://github.com/maxmarcon/live_select/actions/workflows/elixir.yml)

Dynamic selection field for LiveView.

`LiveSelect` is a LiveView component that implements a dynamic selection field with a dropdown. The content of the dropdown is filled dynamically by your LiveView as a reaction to user's input. This allows you to easily implement features like search. It supports both single and multiple selections. 

### [Try the showcase app](https://live-select.fly.dev/) 🔬

### Single selection (single mode) 

![DEMO](https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/demo_single.gif)

### Multiple selection (tags mode)

![DEMO](https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/demo_tags.gif)

## Usage 🧭

Template:

  ```elixir
  <.form for={:my_form} :let={f} phx-change="change">
      <%= live_select f, :city_search %> 
  </.form>
  ```

LiveView:

  ```elixir
  import LiveSelect

  @impl true
  def handle_info(%LiveSelect.ChangeMsg{} = change_msg, socket) do 
    cities = City.search(change_msg.text)

    update_options(change_msg, cities)
    
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "change",
        %{"my_form" => %{"city_search_text_input" => city_name, "city_search" => city_coords}},
        socket
      ) do
    IO.puts("You selected city #{city_name} located at: #{city_coords}")

    {:noreply, socket}
  end  
  ```

Refer to the [module documentation](https://hexdocs.pm/live_select/LiveSelect.html) for the nitty-gritty details.

## Installation 📦

To install, add this to your dependencies:

```elixir
[
    {:live_select, "~> 0.3.0"}
]
```

## Javascript hooks 🪝

`LiveSelect` relies on Javascript hooks to work. You need to add `LiveSelect`'s hooks to your live socket.

In your `app.js` file:

```javascript
import live_select from "live_select"

// if you don't have any other hooks:
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: live_select})


// if you have other hooks:
const hooks = {
    MyHook: {
      // ...
    },
    ...live_select
}
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})
```

## Tailwind configuration 🎨

`LiveSelect` supports 3 styling modes:

* `tailwind`: uses standard tailwind utility classes (the default)
* `daisyui`: uses [daisyUI](https://daisyui.com/) classes.
* `none`: no styling at all.

The choice of style is controlled by the `style` option in [live_select/3](https://hexdocs.pm/live_select/LiveSelect.html#live_select/3).
`tailwind` and `daisyui` styles come with sensible defaults which can be selectively extended or completely overridden.

If you're using `tailwind` or `daisyui` styles, you need to add one of the following lines to the `content` section in your `tailwind.config.js`:

```javascript
module.exports = {
    content: [
        //...
        '../deps/live_select/lib/live_select/component.*ex' <-- for a standalone app
        '../../../deps/live_select/lib/live_select/component.*ex' <-- for an umbrella app
    ]
    //..
}
```

Notice the different paths for a standalone or umbrella app.

Refer to the [Styling section](https://hexdocs.pm/live_select/styling.html) for further details.

## Showcase app 🎪

The repository includes a showcase app that you can use to experiment with the different options and parameters for `LiveSelect`. 
The showcase app is available [here](https://live-select.fly.dev/).

To start the showcase app locally, simply run:

```
mix setup
PORT=4001 mix phx.server
```

from within the cloned repository. The app will be available at http://localhost:4001. The showcase app allows you to quickly experiment with options and styles, providing an easy way to fine tune your `LiveSelect` component. The app also shows the messages and events that your `LiveView` receives. For each event or message, the app shows the function head of the callback that your LiveView needs to implement in order to handle the event.

## Roadmap 🛣️

- [X] Add `package.json` to enable `import live_select from "live_select"`
- [X] Make sure component classes are included by tailwind
- [X] Enable custom styling
- [X] Rename LiveSelect.render to live_select
- [X] Customizable placeholder
- [X] Enable configuration of styles in the showcase app
- [X] Add support for vanilla tailwind styles
- [X] Enable multiple selection mode
- [ ] Expose as function component (and drop LV 0.17 support)
- [ ] Maybe additional multiple selection mode(s)? 
