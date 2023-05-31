export default {
    LiveSelect: {
        textInput() {
            return this.el.querySelector("input[type=text]")
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
        attachDomEventHandlers() {
            this.textInput().onkeydown = (event) => {
                if (event.code === "Enter") {
                    event.preventDefault()
                }
                this.pushEventTo(this.el, 'keydown', {key: event.code})
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
            this.handleEvent("change", ({payload, target}) => {
                if (this.el.id === payload.id) {
                    if (target) {
                        this.pushEventTo(target, "live_select_change", payload)
                    } else {
                        this.pushEvent("live_select_change", payload)
                    }
                }
            })
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