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
      // Clear chart instances in-place (must mutate the internal object,
      // not replace the reference — Chartkick's render closure uses the
      // original object and skips elements with existing instance IDs)
      Object.keys(Chartkick.charts).forEach(function(key) {
        delete Chartkick.charts[key]
      })
      // Trigger Chartkick's DOM scan to create fresh chart instances
      // for both new Turbo Stream elements and existing stable elements
      document.dispatchEvent(new Event("turbo:load"))
    }
  }
}
