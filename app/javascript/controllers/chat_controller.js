import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loader", "input"]

  showLoader() {
    this.loaderTarget.hidden = false
  }

  autoResize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = `${input.scrollHeight}px`
  }

  handleStream(event) {
    const stream = event.target

    // The goal banner was just replaced (goal reached, or dismissed via
    // "Keep going") — scroll it into view since the user may be mid-scroll
    // reading earlier messages and would otherwise miss it entirely.
    if (stream.getAttribute("target") === "goal-banner") {
      requestAnimationFrame(() => {
        const bar = document.querySelector("#goal-banner .goal-bar")
        if (bar) bar.scrollIntoView({ behavior: "smooth", block: "nearest" })
      })
      return
    }

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
