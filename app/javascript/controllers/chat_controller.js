import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["loader", "messages"]

  connect() {
    this.observer = new MutationObserver((mutations) => {
      const assistantWasAdded = mutations.some((mutation) =>
        [...mutation.addedNodes].some((node) => {
          if (!(node instanceof HTMLElement)) return false

          return (
            node.matches?.(".message-row--assistant") ||
            node.querySelector?.(".message-row--assistant") ||
            node.matches?.(".message--assistant") ||
            node.querySelector?.(".message--assistant")
          )
        })
      )

      if (assistantWasAdded) {
        this.hideLoader()

        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            this.scrollToBottom()
          })
        })
      }
    })

    this.observer.observe(this.messagesTarget, {
      childList: true,
      subtree: true
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  showLoader() {
    this.loaderTarget.hidden = false
  }

  hideLoader() {
    this.loaderTarget.hidden = true
  }

  scrollToBottom() {
    const messages = this.messagesTarget.querySelectorAll(".message-row")
    const lastMessage = messages[messages.length - 1]

    lastMessage?.scrollIntoView({
      behavior: "smooth",
      block: "end"
    })
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
