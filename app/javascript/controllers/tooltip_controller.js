import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { content: String }

  connect() {
    if (typeof tippy === "undefined") return

    tippy(this.element, {
      content: this.contentValue,
      delay: [200, 0],
      placement: "top",
      arrow: true,
      animation: "shift-away"
    })
  }
}
