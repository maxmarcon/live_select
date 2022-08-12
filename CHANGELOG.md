# Changelog

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