export default {
    LiveSelect: {
        textInput() {
            return this.el.querySelector("input[type=text]")
        },
        turnHiddenInputIntoTextInput() {
            // TODO: we can leave this an ordinary hidden input when this fix is released: 
            // https://github.com/phoenixframework/phoenix_live_view/commit/2d6495a4fd4e3cc9b67ee631102e65b1bc7912f1
            // (released in LV 0.18.4)
            const hidden_input = this.el.querySelector('input[name=hidden-input]')
            hidden_input.style.display = "none"
            hidden_input.type = "text"
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
                    if (event.target.dataset.idx) {
                        this.textInput().blur()
                        this.pushEventTo(this.el, 'option_click', {idx: event.target.dataset.idx})
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
            const selector = mode === "single" ? "input[name=hidden-input]" : (selection.length === 0 ? "input[name=live_select_empty_selection]" : "input[type=hidden]")
            this.el.querySelector(selector).dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.maybeStyleClearButton();
            this.turnHiddenInputIntoTextInput()
            this.handleEvent("select", ({id, selection, mode, focus, input_event}) => {
                if (this.el.id === id) {
                    if (mode === "single") {
                        const label = selection.length > 0 ? selection[0].label : null
                        this.setInputValue(label, {focus, blur})
                    } else {
                        this.setInputValue(null, {focus, blur})
                    }
                    if (input_event) {
                        this.inputEvent(selection, mode)
                    }
                }
            })
            this.attachDomEventHandlers()
        },
        updated() {
            this.maybeStyleClearButton();
            this.turnHiddenInputIntoTextInput()
            this.attachDomEventHandlers()
        }
    }
}