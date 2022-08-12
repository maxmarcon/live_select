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
            switch (typeof (value)) {
                case "string":
                    break;
                default:
                    value = JSON.stringify(value)
            }
            hidden_input.value = value
            hidden_input.dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.handleEvent("reset", () => {
                this.setSearchInputValue("")
                this.setHiddenInputValue(null)
            })
            this.handleEvent("selected", ({selected: [label, selected]}) => {
                this.setSearchInputValue(label);
                this.setHiddenInputValue(selected)
            })
            this.attachDomEventHandlers()
        },
        updated() {
            this.attachDomEventHandlers()
        }
    }
}