# Styling

`LiveSelect` supports 3 styling modes:

* `tailwind`: uses standard tailwind utility classes (the default)
* `daisyui`: uses [daisyUI](https://daisyui.com/) classes.
* `none`: no styling at all.

The choice of style is controlled by the `style` option in [live_select/3](`LiveSelect.live_select/3`).
`tailwind` and `daisyui` styles come with sensible defaults which can be extended or overridden via options.

This is what each default style looks like:

### daisyui:

<img alt="daisyui example" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/daisyui.png"  width="200">

(the actual colors may differ depending on the selected [daisyui theme](https://daisyui.com/docs/themes/))

### tailwind:

<img alt="tailwind example" src="https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/tailwind.png" width="200">

These defaults can be _selectively overridden or extended_ using the appropriate options
to [live_select/3](`LiveSelect.live_select/3`).

You can control the style of the following elements:

1. The outer **container** of the live_select component
2. The **text input** field
3. The **text input** field when an option has been selected
4. The **dropdown** that contains the selectable options
5. The single selectable **option**(s)
6. The currently **active option**

Here's a visual representation of the elements:

![styled elements](https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/styled_elements.png)

In `tags` mode there adds 3 additional stylable elements:

7. The **tag** showing the selected options
8. The **tags_container** that contains the tags
9. **selected_option**. This is an option in the dropdown that has been selected. It's still visible, but can't be selected again

![styled elements_tags](https://raw.githubusercontent.com/maxmarcon/live_select/main/priv/static/images/styled_elements_tags.png)

For each of these elements there is an `{element}_class` and for some also an `{element}_extra_class` option, which can
be used
to override or extend the default CSS classes for the element, respectively.
You can't use both options together:
use `{element}_class`
to completely override the default classes, or use `{element}_extra_class` to extend the default.

The following table shows the default styles for each element and the options you can use to adjust its CSS classes.

| Element | Default daisyui classes | Default tailwind classes | Class override option | Class extend option |
|----|----|----|----|----|
| *active_option* | active | bg-gray-600 text-white | active_option_class |  |
| *container* | dropdown dropdown-open | h-full relative text-black | container_class | container_extra_class |
| *dropdown* | bg-base-200 cursor-pointer dropdown-content menu menu-compact p-1 rounded-box shadow w-full | absolute bg-gray-100 cursor-pointer rounded-xl shadow w-full z-50 | dropdown_class | dropdown_extra_class |
| *option* |  | hover:bg-gray-400 px-4 py-1 rounded-lg | option_class | option_extra_class |
| *selected_option* | disabled | text-gray-400 | selected_option_class |  |
| *tag* | badge badge-primary p-1.5 text-sm | bg-blue-400 flex p-1 rounded-lg text-sm | tag_class | tag_extra_class |
| *tags_container* | flex flex-wrap gap-1 p-1 | flex flex-wrap gap-1 p-1 | tags_container_class | tags_container_extra_class |
| *text_input* | input input-bordered w-full | disabled:bg-gray-100 disabled:placeholder:text-gray-400 disabled:text-gray-400 rounded-md w-full | text_input_class | text_input_extra_class |
| *text_input_selected* | input-primary | border-gray-600 text-gray-600 | text_input_selected_class |  |


For example, if you want the options to use black text, the active option to have a red background,
and remove rounded borders from both the dropdown and the active option, call [live_select/3](`LiveSelect.live_select/3`)
like this:

```
live_select(form, field,
      active_option_class: "text-white bg-red-800",
      dropdown_extra_class: "!rounded-xl",
      option_extra_class: "!rounded-lg text-black",
      style: :tailwind
)
```

> #### Selectively removing classes from defaults {: .tip}
> 
> You can remove classes included with the style's defaults by using the *!class_name* notation
> in an *{element}_extra_class* option. For example, if a default style is `rounded-lg px-4`,
> using an extra class option of `!rounded-lg text-black` will result in the following final class 
> being applied to the element:
> 
>  `px-4 text-black`


