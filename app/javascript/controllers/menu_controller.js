import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.close = this.close.bind(this)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.element.classList.toggle("is-open")
    this.buttonTarget.setAttribute("aria-expanded", isOpen)

    if (isOpen) {
      document.addEventListener("click", this.close)
    } else {
      document.removeEventListener("click", this.close)
    }
  }

  close() {
    this.element.classList.remove("is-open")
    this.buttonTarget.setAttribute("aria-expanded", false)
    document.removeEventListener("click", this.close)
  }

  disconnect() {
    document.removeEventListener("click", this.close)
  }
}
