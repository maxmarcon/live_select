export default {
    LiveSelect: {
        textInput() {
            return this.el.querySelector("input[type=text]")
        },
        attachDomEventHandlers() {
            this.textInput().onkeydown = (event) => {
                if (event.code === "Enter") {
                    event.preventDefault()
                }
                this.pushEventTo(this.el, 'keydown', {key: event.code})
            }
            this.el.querySelector("ul").onmousedown = (event) => {
                if (event.target.dataset.idx) {
                    this.textInput().blur()
                    this.pushEventTo(this.el, 'option_click', {idx: event.target.dataset.idx})
                }
            }
        },
        setInputValue(value, {focus, blur}) {
            this.textInput().value = value
            if (focus) {
                this.textInput().focus()
            }
        },
        inputEvent(selection, mode) {
            const selector = mode === "single" ? "input.hidden" : (selection.length === 0 ? "input[name=live_select_empty_selection]" : "input[type=hidden]")
            this.el.querySelector(selector).dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
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
            this.attachDomEventHandlers()
        }
    }
}