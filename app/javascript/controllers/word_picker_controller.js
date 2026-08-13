import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["surface"]
  static values = { alreadySaved: Array }

  capture() {
    const selected = window.getSelection().toString().trim()
    if (!selected) return

    this.surfaceTarget.value = selected

    if (this.alreadySavedValue.includes(selected)) {
      this.surfaceTarget.setCustomValidity("You've already saved this word.")
    } else {
      this.surfaceTarget.setCustomValidity("")
    }

    this.surfaceTarget.reportValidity()
  }
}
