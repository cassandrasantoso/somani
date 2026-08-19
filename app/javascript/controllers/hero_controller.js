import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle(event) {
    const expanding = this.panelTarget.hidden
    this.panelTarget.hidden = !expanding
    event.currentTarget.setAttribute("aria-expanded", expanding)
    this.element.classList.toggle("adventure-show__hero--expanded", expanding)
  }
}
