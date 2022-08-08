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

For now, `LiveSelect` requires [DaisyUI](https://daisyui.com/) to be included as tailwind plugin to be styled correctly.
If you are already using Tailwind, installing DaisyUI is as simple as [adding an additional plugin](https://daisyui.com/docs/install/) to your `tailwind.config.js`

In order for tailwind to see the classes used by `LiveSelect`, add the following line to the content section in your `tailwind.config.js`:

```
module.exports = {
    content: [
        ...
        '../deps/live_select/lib/live_select/component.*ex'
    ],

    ...
}
```

**NOTE:** you might need to add an additional `..` if your application is an umbrella app


## Usage

Refer to the [module's documentation](`LiveSelect`).

## TODO

 - [X] Add `package.json` to enable `import live_select from "live_select"`
 - [X] Make sure component classes are included by tailwind 
 - [ ] Enable custom styling 