# LiveSelect

`LiveSelect` is a simple LiveView component that implements a dynamic search and selection
field that can be filled dynamically by your application. It has no external dependencies apart from
LiveView. It is styling agnostic but comes with optional pre-configured styles
using [Tailwindcss](https://tailwindcss.com/)
and [DaisyUI](https://daisyui.com/).

![Demo](priv/static/images/demo.gif)

## Installation

To install, add this to your dependencies:

```
[
    {:live_select, "~> 0.1.0"}
]
```

## Javascript Hooks

`LiveSelect` relies on Javascript hooks to operate correctly. You need to add `LiveSelect`'s hooks to your websocket
connection.
In your `app.js` file:

```
import live_select from "./live_select"

...
// if you don't have any other hooks you can do this
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: live_select})


// if you have other hooks you can do this
let hooks = Object.assign(my_hooks, live_select)
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})
```

## Usage

Refer to the [module's documentation](`LiveSelect`).

## TODO

 - [ ] Add `package.json` to enable `import live_select from "live_select"`
 - [ ] Make sure component classes are included by tailwind 
 - [ ] Enable custom styling 