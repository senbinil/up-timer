import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.boundClose = this.#clickOutside.bind(this)
  }

  open() {
    this.modalTarget.showModal()
    this.modalTarget.addEventListener("click", this.boundClose)
  }

  close() {
    this.modalTarget.close()
    this.modalTarget.removeEventListener("click", this.boundClose)
  }

  #clickOutside(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}
