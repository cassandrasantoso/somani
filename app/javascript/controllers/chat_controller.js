import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loader", "input", "messages"]

  connect() {
    this.scrollToBottom(false)
  }

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
      return
    }

    // Only care about Turbo streams adding messages
    if (stream.getAttribute("target") !== "messages") return

    const template = stream.templateElement
    const assistantMessage = template.content.querySelector(".message--assistant")

    if (assistantMessage) {
      this.hideLoader()
    }

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.scrollToBottom()
      })
    })
  }

  hideLoader() {
    this.loaderTarget.hidden = true
  }

  scrollToBottom(smooth = true) {
    const lastMessage = this.messagesTarget.lastElementChild

    lastMessage?.scrollIntoView({
      behavior: smooth ? "smooth" : "auto",
      block: "end"
    })
  }
}
