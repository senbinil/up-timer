import { Controller } from "@hotwired/stimulus"

const BODY_METHODS = ["POST", "PUT", "PATCH"]

export default class extends Controller {
  static targets = ["body"]

  toggle(e) {
    const show = BODY_METHODS.includes(e.target.value)
    this.bodyTarget.classList.toggle("hidden", !show)
  }
}
