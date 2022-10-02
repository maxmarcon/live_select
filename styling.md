# Styling

`LiveSelect` supports 3 styling modes:

* `tailwind`: uses standard tailwind utility classes (the default)
* `daisyui`: uses [daisyUI](https://daisyui.com/) classes.
* `none`: no styling at all.

The choice of style is controlled by the `style` option in `LiveSelect.live_select/3`.
`tailwind` and `daisyui` styles come with sensible defaults which can be selectively extended or completely overridden.

This is what each default style looks like:

### daisyui:

<img alt="daisyui example" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/daisyui.png"  width="200">

(actual colors may differ depending on the selected [daisyui theme](https://daisyui.com/docs/themes/)):

### tailwind:

<img alt="tailwind example" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/tailwind.png" width="200">

These defaults can be _selectively overridden or extended_ using the appropriate options to `LiveSelect.live_select/3`.

1. The outer container of the component
2. The text field
3. The text field when an option has been selected
4. The dropdown with the options
5. The active option the user navigated to using the arrow keys

For each of these components there is a `{component}_class` and for some a `{component}_extra_class` option, which can
be used
to either override or extend the default CSS classes for the component. You can't use both options together:
use `{component}_class`
to completely override the default classes, or use `{component}_extra_class` to extend the default.

The following table shows the default styles for each component and the options you can use to adjust its CSS classes.

|Component|Default daisyUI classes|class override option|class extend option|
|--|--|--|--|
|*outer container*|"dropdown"|`container_class`|`container_extra_class`|
|*text field*|"input input-bordered"|`text_input_class`|`text_input_extra_class`|
|*text field selected*|"input-primary text-primary"|`text_input_selected_class`| |
|*dropdown*|"dropdown-content menu menu-compact shadow rounded-box"|`dropdown_class`|`dropdown_extra_class`|
|*active option*|"active"|`active_option_class`| |

For example, if you want to show a full-width LiveSelect component with a secondary color for the dropdown background
and active options with a warning background, you can do this:

  ```
  live_select(form, field,
      container_extra_class: "w-full",
      text_input_extra_class: "w-full",
      dropdown_extra_class: "w-full bg-secondary",
      active_option_class: "bg-warning"
    )
  ```

Result:

![](assets/styled.jpg)

You can remove classes included by the style's defaults using the "!class_name" notation.

For example, to remove the border from the default styles for the text input in daisyui and make the background white
, you can do:

  ```
  live_select(form, field,
      text_input_extra_class: "!input-bordered bg-white",
    )
  ```
