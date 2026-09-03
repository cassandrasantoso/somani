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

    if (stream.getAttribute("target") === "goal-banner") {
      requestAnimationFrame(() => {
        const bar = document.querySelector("#goal-banner .goal-bar")

        if (bar) {
          bar.scrollIntoView({
            behavior: "smooth",
            block: "nearest"
          })
        }
      })
    }
  }

  hideLoader() {
    this.loaderTarget.hidden = true
  }

  scrollToBottom() {
    const lastMessage = this.messagesTarget.lastElementChild

    lastMessage?.scrollIntoView({
      behavior: "smooth",
      block: "end"
    })
  }
}
