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
        setInputValue(value) {
            this.el.querySelector("input[type=text]").value = value;
        },
        setHiddenInputValue(value) {
            const hidden_input = this.el.querySelector("input[type=hidden]")
            hidden_input.value = value == null || typeof (value) === 'string' ? value : JSON.stringify(value)
            hidden_input.dispatchEvent(new Event('input', {bubbles: true}))
        },
        mounted() {
            this.handleEvent("reset", ({id: id}) => {
                if (this.el.id === id) {
                    this.setInputValue(null)
                    this.setHiddenInputValue(null)
                }
            })
            this.handleEvent("select", ({id: id, selection: [{label: label, selected: selected}]}) => {
                if (this.el.id === id) {
                    this.setInputValue(label);
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