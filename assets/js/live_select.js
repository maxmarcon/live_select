function debounce(func, msec) {
    let timer;
    return (...args) => {
        clearTimeout(timer)
        timer = setTimeout(() => {
            func.apply(this, args)
        }, msec)
    }
}

export default {
    LiveSelect: {
        textInput() {
            return this.el.querySelector("input[type=text]")
        },
        debounceMsec() {
            return parseInt(this.el.dataset["debounce"])
        },
        updateMinLen() {
            return parseInt(this.el.dataset["updateMinLen"])
        },
        maybeStyleClearButtons() {
            const clear_button = this.el.querySelector('button.ls-clear-button')
            if (clear_button) {
                this.textInput().parentElement.style.position = 'relative'
                this.textInput().parentElement.style.display = 'flex'
                this.textInput().parentElement.style.alignItems = 'center'
                clear_button.style.minHeight = '20px'
                clear_button.style.minWidth = '20px'
                clear_button.style.position = 'absolute'
                clear_button.style.right = '5px'
                clear_button.style.display = 'block'
            }
            this.el.querySelectorAll('button.ls-clear-tag-button').forEach(clear_button => {
                clear_button.style.minHeight = '20px'
                clear_button.style.minWidth = '20px'
            })
        },
        pushEventToParent(event, payload) {
            const target = this.el.dataset['phxTarget'];
            if (target) {
                this.pushEventTo(target, event, payload)
            } else {
                this.pushEvent(event, payload)
            }
        },
        attachDomEventHandlers() {
            this.textInput().onkeydown = (event) => {
                if (event.code === "Enter") {
                    event.preventDefault()
                }
                this.pushEventTo(this.el, 'keydown', { key: event.code })
            }
            this.changeEvents = debounce((id, field, text) => {
                this.pushEventTo(this.el, "change", { text })
                this.pushEventToParent("live_select_change", { id: this.el.id, field, text })
            }, this.debounceMsec())
            this.textInput().oninput = (event) => {
                const text = event.target.value.trim()
                const field = this.el.dataset['field']
                if (text.length >= this.updateMinLen()) {
                    this.changeEvents(this.el.id, field, text)
                } else {
                    this.pushEventTo(this.el, "options_clear", {})
                }
            }
            const dropdown = this.el.querySelector("ul")
            if (dropdown) {
                dropdown.onmousedown = (event) => {
                    const option = event.target.closest('div[data-idx]')
                    if (option) {
                        this.pushEventTo(this.el, 'option_click', { idx: option.dataset.idx })
                        event.preventDefault()
                    }
                }
            }
            this.el.querySelectorAll("button[data-idx]").forEach(button => {
                button.onclick = (event) => {
                    this.pushEventTo(this.el, 'option_remove', { idx: button.dataset.idx })
                }
            })
        },
        setInputValue(value) {
            this.textInput().value = value
        },
        inputEvent(selection, mode) {
            const selector = mode === "single" ? "input.single-mode" : (selection.length === 0 ? "input[data-live-select-empty]" : "input[type=hidden]")
            this.el.querySelector(selector).dispatchEvent(new Event('input', { bubbles: true }))
        },
        mounted() {
            this.maybeStyleClearButtons()
            this.handleEvent("select", ({ id, selection, mode, current_text, input_event, parent_event }) => {
                if (this.el.id === id) {
                    this.selection = selection
                    if (current_text !== null) {
                        this.setInputValue(current_text)
                    }
                    if (input_event) {
                        this.inputEvent(selection, mode)
                    }
                    if (parent_event) {
                        this.pushEventToParent(parent_event, { id })
                    }
                }
            })
            this.handleEvent("active", ({ id, idx }) => {
                if (this.el.id === id) {
                    const option = this.el.querySelector(`div[data-idx="${idx}"]`)
                    if (option) {
                        option.scrollIntoView({ block: "nearest" })
                    }
                }
            })
            this.attachDomEventHandlers()
        },
        updated() {
            this.maybeStyleClearButtons()
            this.attachDomEventHandlers()
        },
        reconnected() {
            if (this.selection && this.selection.length > 0) {
                this.pushEventTo(this.el, "selection_recovery", this.selection)
            }
        }
    }
}
