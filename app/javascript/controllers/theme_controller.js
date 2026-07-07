import { Controller } from "@hotwired/stimulus"

// Theme controller — toggles dark mode, persists to localStorage.
// Initial theme is applied via an inline script in <head> to prevent flash.

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    // Ensure the class matches stored preference
    const stored = localStorage.getItem("theme")
    if (stored === "dark") {
      document.documentElement.classList.add("dark")
    } else {
      document.documentElement.classList.remove("dark")
    }
    this.updateMetaTheme()
  }

  toggle() {
    const isDark = document.documentElement.classList.toggle("dark")
    localStorage.setItem("theme", isDark ? "dark" : "light")
    this.updateMetaTheme()

    // Reinitialize Lucide icons after toggle
    if (window.lucide) {
      lucide.createIcons()
    }
  }

  updateMetaTheme() {
    const isDark = document.documentElement.classList.contains("dark")
    const meta = document.querySelector('meta[name="theme-color"]')
    if (meta) {
      meta.content = isDark ? "#0f172a" : "#f7f9fb"
    }
  }
}
