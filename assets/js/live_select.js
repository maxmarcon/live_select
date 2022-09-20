export default {
    LiveSelect: {
        attachDomEventHandlers() {
            this.el.querySelector("input[type=text]").onkeydown = (event) => {
                if (event.code == "Enter") {
                    event.preventDefault()
                }
                this.pushEventTo(this.el, 'keydown', {key: event.code})
            }
            this.el.querySelector("ul").onmouseover = () => {
                this.pushEventTo(this.el, 'dropdown-mouseover', {})
            }
            this.el.querySelector("ul").onmouseleave = () => {
                this.pushEventTo(this.el, 'dropdown-mouseleave', {})
            }
        },
        setSearchInputValue(value) {
            this.el.querySelector("input[type=text]").value = value;
        },
        setHiddenInputValue(value) {
            const hidden_input = this.el.querySelector("input[type=hidden]")
            hidden_input.value = typeof (value) === 'string' ? value : JSON.stringify(value)
            hidden_input.dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.handleEvent("reset", ({id: id}) => {
                if (this.el.id === id) {
                    this.setSearchInputValue("")
                    this.setHiddenInputValue("")
                }
            })
            this.handleEvent("selected", ({id: id, selected: [label, selected]}) => {
                if (this.el.id === id) {
                    this.setSearchInputValue(label);
                    this.setHiddenInputValue(selected)
                }
            })
            this.attachDomEventHandlers()
        },
        updated() {
            this.attachDomEventHandlers()
        }
    }
}