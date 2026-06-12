import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "severity", "message"]

  setSeverity() {
    const id = this.triggerTarget.value
    if (!id) return

    const severities = JSON.parse(this.triggerTarget.dataset.severities)
    const severity = severities[id]
    if (severity) this.severityTarget.value = severity

    const name = this.triggerTarget.selectedOptions[0].text
    if (name && !this.messageTarget.value) {
      this.messageTarget.value = `${name}: `
    }
  }
}
