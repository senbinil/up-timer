import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  toggle() {
    this.sidebarTarget.classList.toggle("hidden")
  }

  close() {
    this.sidebarTarget.classList.add("hidden")
  }
}
