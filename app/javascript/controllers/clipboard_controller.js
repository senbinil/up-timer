import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    text: String
  }

  copy() {
    const text = this.textValue
    const button = this.element
    const originalText = button.textContent

    // Try Clipboard API first (requires secure context: HTTPS or localhost)
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(
        () => this._showFeedback(button, originalText),
        () => this._fallbackCopy(text, button, originalText)
      )
    } else {
      this._fallbackCopy(text, button, originalText)
    }
  }

  _fallbackCopy(text, button, originalText) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()

    try {
      document.execCommand("copy")
      this._showFeedback(button, originalText)
    } catch {
      button.textContent = "Failed"
      button.classList.add("btn-error")
      setTimeout(() => {
        button.textContent = originalText
        button.classList.remove("btn-error")
      }, 2000)
    } finally {
      document.body.removeChild(textarea)
    }
  }

  _showFeedback(button, originalText) {
    button.textContent = "Copied!"
    button.classList.add("btn-success")
    setTimeout(() => {
      button.textContent = originalText
      button.classList.remove("btn-success")
    }, 2000)
  }
}
