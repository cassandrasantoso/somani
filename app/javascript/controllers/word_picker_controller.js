import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["surface"]

  capture() {
    const selected = window.getSelection().toString().trim()
    if (selected) this.surfaceTarget.value = selected
  }
}
