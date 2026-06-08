import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open() {
    this.element.showModal()
  }

  close() {
    this.element.close()
  }

  clickOutside(e) {
    if (e.target === this.element) this.close()
  }
}
