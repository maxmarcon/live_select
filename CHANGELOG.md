# Changelog

## 0.2.1

* when disabled option is used, also disable hidden input
* style disabled text input in tailwind mode
* fix problem with selection via mouseclick when an input field is underneath the dropdown
* hide dropdown when user clicks away from component or input loses focus
* show dropdown when input obtains focus again

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