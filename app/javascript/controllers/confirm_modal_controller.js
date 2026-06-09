import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, message: String }

  connect() {
    this.boundOpen = this.open.bind(this)
    document.addEventListener("confirm-modal:open", this.boundOpen)
  }

  disconnect() {
    document.removeEventListener("confirm-modal:open", this.boundOpen)
  }

  open(e) {
    this.urlValue = e.detail.url
    this.messageValue = e.detail.message || "Are you sure?"
    document.getElementById("confirm-message").textContent = this.messageValue
    document.getElementById("confirm-modal").showModal()
  }

  proceed() {
    const form = document.getElementById("confirm-form")
    form.action = this.urlValue
    form.submit()
  }

  close() {
    document.getElementById("confirm-modal").close()
  }

  clickOutside(e) {
    if (e.target.id === "confirm-modal") this.close()
  }
}
