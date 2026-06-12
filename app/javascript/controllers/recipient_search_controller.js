import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const q = this.inputTarget.value
      const url = new URL("/alert_integrations/search_recipients", window.location.origin)
      url.searchParams.set("q", q)

      Turbo.visit(url, { frame: "recipients_list" })
    }, 200)
  }
}
