# Styling

You can use the `style` option in `live_select/3` to control which style will be used by default. Currently supported values are
`:daisyui` (default) or `:none` (no predefined styles). Support for vanilla Tailwind styles is planned for the future. LiveSelect can style the following elements:

1. The outer container of the component
2. The text field
3. The text field when an option has been selected
4. The dropdown with the options
5. The active option the user navigated to using the arrow keys

For each of these components there is a `{component}_class` and for some a `{component}_extra_class` option, which can be used
to either override or extend the default CSS classes for the component. You can't use both options together: use `{component}_class`
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
