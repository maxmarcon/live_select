export default {
    LiveSelect: {
        setSearchInputValue(value) {
            this.el.querySelector("input[type=text]").value = value;
        },
        setHiddenInputValue(value) {
            const hidden_input = this.el.querySelector("input[type=hidden]")
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
            this.el.querySelector("input[type=text]").onkeydown = (event) => {
                switch (event.code) {
                    case 'Enter':
                        event.preventDefault()
                        this.pushEventTo(this.el, 'enter', {})
                        break;
                    case 'ArrowDown':
                        this.pushEventTo(this.el, 'results-down', {})
                        break;
                    case 'ArrowUp':
                        this.pushEventTo(this.el, 'results-up', {})
                        break;
                }
            }
            this.el.querySelector(".dropdown-content").onmouseover = () => {
                this.pushEventTo(this.el, 'dropdown-mouseover', {})
            }
            this.el.querySelector(".dropdown-content").onmouseleave = () => {
                this.pushEventTo(this.el, 'dropdown-mouseleave', {})
            }
        }
    }
}