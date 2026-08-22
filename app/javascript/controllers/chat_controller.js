import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loader"]

  showLoader() {
    this.loaderTarget.hidden = false
  }

  handleStream(event) {
    const stream = event.target

    // Only care about Turbo streams adding messages
    if (stream.getAttribute("target") !== "messages") return

    const template = stream.templateElement

    // Check whether the incoming message is an AI message
    const assistantMessage = template.content.querySelector(".message--assistant")

    if (assistantMessage) {
      this.hideLoader()
    }
  }

  hideLoader() {
    this.loaderTarget.hidden = true
  }
}
