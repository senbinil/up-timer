import { Controller } from "@hotwired/stimulus"

// Re-initializes Chartkick charts after Turbo Stream replaces content
// Chartkick only listens to DOMContentLoaded and turbo:load, not turbo:render
export default class extends Controller {
  connect() {
    this.boundRedraw = this.redrawCharts.bind(this)
    document.addEventListener("turbo:render", this.boundRedraw)
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.boundRedraw)
  }

  redrawCharts() {
    if (window.Chartkick) {
      // Clear stale chart instances from previous page
      window.Chartkick.charts = {}
    }
  }
}
