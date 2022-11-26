export default {
    LiveSelect: {
        attachDomEventHandlers() {
            this.el.querySelector("input[type=text]").onkeydown = (event) => {
                if (event.code === "Enter") {
                    event.preventDefault()
                }
                this.pushEventTo(this.el, 'keydown', {key: event.code})
            }
        },
        setInputValue(value) {
            this.el.querySelector("input[type=text]").value = value
        },
        inputEvent(mode) {
            const selector = mode === "single" ? "input[type=hidden]" : "select"
            this.el.querySelector(selector).dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.handleEvent("reset", ({id}) => {
                if (this.el.id === id) {
                    this.setInputValue(null)
                    this.inputEvent("single")
                }
            })
            this.handleEvent("select", ({id, selection, mode}) => {
                if (this.el.id === id) {
                    if (mode === "single") {
                        const [{label}] = selection
                        this.setInputValue(label)
                        this.inputEvent(mode)
                    } else {
                        this.setInputValue(null)
                        this.inputEvent(mode)
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