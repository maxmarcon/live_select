# LiveSelect

`LiveSelect` is a simple LiveView component that implements a dynamic search and selection
field that can be filled dynamically by your application. It has no external dependencies apart from
LiveView. It comes with optional pre-configured styles
for [DaisyUI](https://daisyui.com/) and [Tailwindcss](https://tailwindcss.com/) (coming soon).

![Demo](assets/demo.gif)

## Installation

To install, add this to your dependencies:

```
[
    {:live_select, "~> 0.1.0"}
]
```

## Javascript Hooks

`LiveSelect` relies on Javascript hooks to work. You need to add `LiveSelect`'s hooks to your live socket.

In your `app.js` file:

```
import live_select from "live_select"

...
// if you don't have any other hooks you can do this
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: live_select})


// if you have other hooks you can do this
let hooks = Object.assign(my_hooks, live_select)
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})
```

## Styling

`LiveSelect` supports 2 styling options: styling with [daisyUI](https://daisyui.com/) or custom styling. The choice
of styling is controlled using the `style` option in `LiveSelect.render/3`.

If you want to use daisyUI styles, you'll have to install daisyUI. This is as simple as [adding an additional plugin](https://daisyui.com/docs/install/) to your `tailwind.config.js`
Moreover, in order for tailwind to see the daisyUI classes used by `LiveSelect`, add the following line to the content section in your `tailwind.config.js`:

```
module.exports = {
    content: [
        ...
        '../deps/live_select/lib/live_select/component.*ex'
    ],

    ...
}
```

**NOTE:** you might need an additional `..` in the path if your application is an umbrella app


## Usage

Refer to the [module's documentation](./lib/live_select.ex).

## TODO

 - [X] Add `package.json` to enable `import live_select from "live_select"`
 - [X] Make sure component classes are included by tailwind 
 - [ ] Enable custom styling 
 - [ ] Enable tailwind styles
 - [ ] Rename LiveSelect.render
 - [ ] Enable slots