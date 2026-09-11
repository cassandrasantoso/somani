import { Controller } from "@hotwired/stimulus"
import { bind, unbind } from "wanakana"

export default class extends Controller {
  static targets = ["input", "toggle"]

  connect() {
    this.bound = false
  }

  toggle() {
    if (this.bound) {
      unbind(this.inputTarget)
      this.bound = false
      this.toggleTarget.textContent = "あ"
      this.toggleTarget.setAttribute("aria-pressed", "false")
    } else {
      bind(this.inputTarget)
      this.bound = true
      this.toggleTarget.textContent = "A"
      this.toggleTarget.setAttribute("aria-pressed", "true")
    }
  }

  disconnect() {
    if (this.bound) unbind(this.inputTarget)
  }
}
