import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.open = false
  }

  toggle() {
    this.open = !this.open
    this.menuTarget.classList.toggle("open", this.open)
    const menuWrap = this.element.querySelector('[data-dashboard-mobile-nav-target="menuIconWrap"]')
    const closeWrap = this.element.querySelector('[data-dashboard-mobile-nav-target="closeIconWrap"]')
    if (menuWrap) menuWrap.classList.toggle("hidden", this.open)
    if (closeWrap) closeWrap.classList.toggle("hidden", !this.open)
  }

  close(event) {
    if (this.open && !this.element.contains(event.target)) {
      this.open = false
      this.menuTarget.classList.remove("open")
      const menuWrap = this.element.querySelector('[data-dashboard-mobile-nav-target="menuIconWrap"]')
      const closeWrap = this.element.querySelector('[data-dashboard-mobile-nav-target="closeIconWrap"]')
      if (menuWrap) menuWrap.classList.remove("hidden")
      if (closeWrap) closeWrap.classList.add("hidden")
    }
  }

  closeKey(event) {
    if (event.key === "Escape" && this.open) {
      this.open = false
      this.menuTarget.classList.remove("open")
      const menuWrap = this.element.querySelector('[data-dashboard-mobile-nav-target="menuIconWrap"]')
      const closeWrap = this.element.querySelector('[data-dashboard-mobile-nav-target="closeIconWrap"]')
      if (menuWrap) menuWrap.classList.remove("hidden")
      if (closeWrap) closeWrap.classList.add("hidden")
    }
  }
}
