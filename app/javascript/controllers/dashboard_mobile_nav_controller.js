import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "menuIcon", "closeIcon"]

  connect() {
    this.open = false
  }

  toggle() {
    this.open = !this.open
    this.menuTarget.classList.toggle("open", this.open)
    this.menuIconTarget.classList.toggle("hidden", this.open)
    this.closeIconTarget.classList.toggle("hidden", !this.open)
  }

  close(event) {
    if (this.open && !this.element.contains(event.target)) {
      this.open = false
      this.menuTarget.classList.remove("open")
      this.menuIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
    }
  }

  closeKey(event) {
    if (event.key === "Escape" && this.open) {
      this.open = false
      this.menuTarget.classList.remove("open")
      this.menuIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
    }
  }
}
