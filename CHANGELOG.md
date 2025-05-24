## [Unreleased]

### Added
* DaisyUI 5 compatibility - active options now include both `active` and `menu-active` classes for compatibility with DaisyUI 3, 4, and 5.

## 1.6.0 (2025-04-13)

* add ability to disable options

## 1.5.5 (2025-03-31)

* make clear buttons also honor the disabled attribute
* remember entered text when blurring away from the element

## 1.5.4 (2025-01-29)

* Fix [bug](https://github.com/maxmarcon/live_select/issues/98) causing selection recovery to fail if Phoenix uses the built-in JSON module from Elixir 1.18

## 1.5.3 (2025-01-27)

* Fix [bug](https://github.com/maxmarcon/live_select/issues/96) that causes selection recovery to fail when `input_for` is used to render the component
* Remove dependency from `Jason` library

## 1.5.2 (2024-12-28)

* Fix [bug](https://github.com/maxmarcon/live_select/issues/70) where the keyboard doesn't show on some mobile browsers if an element is already selected in single mode

## 1.5.1 (2024-12-28)

* Add unavailable_option_class to style options that cannot be selected because of max_selectable > 0
* Fix can't remove items in quick_tags mode via dropdown with max_selectable

## 1.5.0 (2024-12-27)

* new quick_tags mode 
* showcase app: add toggle to style options as checkboxes

## 1.4.4 (2024-12-07)

* support for LiveView 1.0.0

## 1.4.3 (2024-10-28)

* add options clear_tag_button_class and clear_tag_button_extra_class to style button to clear tags
* fix [bug](https://github.com/maxmarcon/live_select/issues/81) where selection was not restored after focus+blur when value is pre-selected or forced 
  
## 1.4.2 (2024-06-19)

do not restore selection after blur it it was cleard by hitting the clear button

## 1.4.1 (2024-06-18)

* fix bug introduced by LV-1.0's new focus behavior (https://github.com/maxmarcon/live_select/issues/72)

## 1.4.0 (2024-03-18)

* support for associations and embeds
* add `value_mapper` assign and `decode/1` function

## 1.3.3 (2024-02-06)

* add slot to render custom clear button
* add option to extend clear button style

## 1.3.2 (2024-01-26)

* updated dependencies, including updating `phoenix_html` to `4.0.0`

## 1.3.1 (2023-12-06)

* bugfix: only set selection in client if event was sent to this component

## 1.3.0 (2023-12-05)

* added support for selection recovery. Upon reconnection, the client sends an event (`selection_recovery`) that contains the latest selection. This allows recovery of the selection that was active before the view disconnected.

## 1.2.2 (2023-10-21)

* daisyui3-compatible
* arrowUp when there is no active option navigates to the last option
* scroll options into view when they become active

## 1.2.1 (2023-10-17)

* fix bug that was causing dropdown to overflow container (https://github.com/maxmarcon/live_select/issues/43)

## 1.2.0 (2023-09-25)

* add `clear_button_class` option to style clear buttons for tags and selection
* various bugfixes and improvements

## 1.1.1 (2023-07-21)

* accept `sticky` flag in an option to prevent it from being removed (https://github.com/maxmarcon/live_select/pull/33)
* when selection becomes empty, an update is triggered with a hidden field named after `live_select`'s field's name

(thanks to https://github.com/shamanime for both changes)

## 1.1.0 (2023-06-26)

* add `phx-focus` and `phx-blur` options to specify events to be sent to the parent upon focus and blur of the text input field
* send live_select_change event directly from JS hook to save a round-trip
* expects a single `field` assign of type `Phoenix.HTML.FormField` instead of separate form and field assigns (which is still supported but soft-deprecated with a warning)

## 1.0.4 (2023-05-30)

* Do not use name attribute on non-input elements to prevent LV from crashing
* Change default for update_min_len to 1

## 1.0.3 (2023-03-31)

* Programmatically override selection with value assign
* Only clear options if entered text is shorter than update_min_len and user types backspace

Bugfix: fix selection via mouseclick not working when rendering nested elements in the :option slot

## 1.0.2 (2023-03-20)

styling options now also accept lists of strings

## 1.0.1 (2023-02-18)

Bugfix: fix error when using atom form

## 1.0.0 (2023-02-15)

This version introduces the following breaking changes and new features:

* Rendering using a function component `<.live_select />` instead of the old function style (`<%= live_select ... %>`)
* Dropping the message-based update cycle (which used `handle_info/2`) in favour of an event-based update cycle (which uses `handle_event/3`). This makes it much easier
and more intuitive to use LiveSelect from another LiveComponent.
* Ability to customize the default rendering of dropdown entries and tags using the `:option` and `:tag` slots 

** How to upgrade from version 0.x.x: **

1. Instead of rendering LiveSelect in this way: `<%= live_select form, field, mode: :tags %>`, render it in this way: `<.live_select form={form} field={field} mode={:tags} />`
2. Don't forget to add `phx-target={@myself}` if you're using LiveSelect from another LiveComponent
3. Turn your `handle_info/2` implementations into `handle_event/3`:

Turn this:

```elixir
def handle_info(%ChangeMsg{} = change_msg, socket) do
     options = retrieve_options(change_msg.text)
    
     send_update(LiveSelect.Component, id: change_msg.id, options: options)
    
     {:noreply, socket}
end
```

into:

```elixir
def handle_event("live_select_change", %{"text" => text, "id" => live_select_id}, socket) do
    options = retrieve_options(text)
    
    send_update(LiveSelect.Component, id: live_select_id, options: options)
    
    {:noreply, socket}
end
```

4. If you're rendering LiveSelect in a LiveComponent, you can now place your `handle_event/3` callback in the LiveComponent, there's no need to put the update logic in the view anymore

## 0.4.1 (2023-02-07)

Bugfix: component now works event when strict Content Security Policy are set

## 0.4.0 (2023-01-30)

* add `available_option_class` configuration option to style options that have not been selected yet
* add `user_defined_options` configuration option to allow user to enter any tag
* enable assigning a custom id to the component
* enable programmatically clearing of the selection via `clear` assign
* add `allow_clear` configuration option. If set, an `x` button will appear next to the text input in single mode. Clicking the button clears the selection

### Deprecations

LiveSelect.update_options/2 has been deprecated in favor of directly using Phoenix.LiveView.send_update/3 

## 0.3.3 (2023-01-15)

* set initial selection from the form or manually with `value` option
* set initial list of available options with `options` option
* add a `max_selectable` option to limit the maximum size of the selection

## 0.3.2 (2023-01-03)

Bugfix: options in dropdown not always clickable because of race condition with blur event (https://github.com/maxmarcon/live_select/issues/7)

## 0.3.1 (2022-12-15)

Bugfix: removed inputs_for because it was failing if the field is not an association

## 0.3.0 (2022-12-15)

* tags mode
* hide dropdown on escape key pressed

## 0.2.1 (2022-10-25)

* when disabled option is used, also disable hidden input
* style disabled text input in tailwind mode
* fix problem with selection via mouseclick when an input field is underneath the dropdown
* hide dropdown when user clicks away from component or input loses focus
* show dropdown when input obtains focus again
* using default black text in tailwind mode 

## 0.2.0 (2022-10-03)

* support for tailwind styles (now the default)
* more opinionated default styles
* ability to selectively remove classes from style defaults using the !class_name notation
* rename option search_term_min_length to update_min_len
* better error messages
* various improvements to the showcase app

## 0.1.4 (2022-09-20)

* raise if class and extra_class options are used in invalid combinations (https://github.com/maxmarcon/live_select/issues/2)

### Bugfixes

* route server events to the right live select component using the component `id` (https://github.com/maxmarcon/live_select/issues/1)

## 0.1.3 (2022-08-12)

* rename LiveSelect.update/2 to LiveSelect.update_options/2
* add debounce option
* add search delay option to showcase app
* JSON-encode option values before assigning them to the hidden input field
* add LiveSelect.ChangeMsg struct to be used as change message

## 0.1.2 (2022-08-10)

* Disable input field via options
* Placeholder text via options
* Improve docs and showcase app
* Remove setting component id via options

### Bugfixes

* Use atoms as field names, because strings are not accepted by Ecto forms

## 0.1.1 (2022-08-09)

* Remove all colors from default daisyui styles
* Improve styling of showcase app
* Improve docs
* Remove the `msg_prefix` option in favor of `change_msg`

## 0.1.0 (2022-08-09)

First version 🎉
