import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  // story 6 — never a server round-trip; the text is already in the DOM
  toggle(event) {
    event.currentTarget.previousElementSibling.classList.toggle("blurred")
  }
}
