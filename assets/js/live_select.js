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
        setInputValue(value, setFocus) {
            this.textInput().value = value
            if (setFocus) {
                this.textInput().focus()
            }
        },
        inputEvent(selection, mode) {
            const selector = mode === "single" ? "input.hidden" : (selection.length === 0 ? "input[name=live_select_empty_selection]" : "input[type=hidden]")
            this.el.querySelector(selector).dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.handleEvent("reset", ({id}) => {
                if (this.el.id === id) {
                    this.setInputValue(null, true)
                    this.inputEvent([], "single")
                }
            })
            this.handleEvent("select", ({id, selection, mode}) => {
                if (this.el.id === id) {
                    if (mode === "single") {
                        const [{label}] = selection
                        this.setInputValue(label)
                        this.inputEvent(selection, mode)
                    } else {
                        this.setInputValue(null)
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