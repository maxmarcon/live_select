export default {
    LiveSelect: {
        textInput() {
            return this.el.querySelector("input[type=text]")
        },
        updateMinLen() {
            return parseInt(this.el.dataset["updateMinLen"])
        },
        maybeStyleClearButton() {
            const clear_button = this.el.querySelector('button[phx-click=clear]')
            if (clear_button) {
                this.textInput().style.position = 'relative'
                clear_button.style.position = 'absolute'
                clear_button.style.top = '0px'
                clear_button.style.bottom = '0px'
                clear_button.style.right = '5px'
            }
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

                this.pushEventTo(this.el, 'keydown', {key: event.code})
            }
            this.textInput().oninput = (event) => {
                const text = event.target.value.trim()
                const field = this.el.dataset['textInputField']
                if (text.length >= this.updateMinLen()) {
                    this.pushEventTo(this.el, "change", {text})
                    this.pushEventToParent("live_select_change", {id: this.el.id, field, text})
                } else {
                    this.pushEventTo(this.el, "options_clear", {})
                }
            }
            const dropdown = this.el.querySelector("ul")
            if (dropdown) {
                dropdown.onmousedown = (event) => {
                    const option = event.target.closest('div[data-idx]')
                    if (option) {
                        this.textInput().blur()
                        this.pushEventTo(this.el, 'option_click', {idx: option.dataset.idx})
                    }
                }
            }
        },
        setInputValue(value, {focus}) {
            this.textInput().value = value
            if (focus) {
                this.textInput().focus()
            }
        },
        inputEvent(selection, mode) {
            const selector = mode === "single" ? "input[class=single-mode]" : (selection.length === 0 ? "input[name=live_select_empty_selection]" : "input[type=hidden]")
            this.el.querySelector(selector).dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.maybeStyleClearButton()
            this.handleEvent("select", ({id, selection, mode, focus, input_event}) => {
                if (this.el.id === id) {
                    if (mode === "single") {
                        const label = selection.length > 0 ? selection[0].label : null
                        this.setInputValue(label, {focus})
                    } else {
                        this.setInputValue(null, {focus})
                    }
                    if (input_event) {
                        this.inputEvent(selection, mode)
                    }
                }
            })
            this.attachDomEventHandlers()
        },
        updated() {
            this.maybeStyleClearButton()
            this.attachDomEventHandlers()
        }
    }
}