import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["button", "icon", "label"]

  connect() {
    this.audio = new Audio(this.urlValue)

    this.audio.addEventListener("ended", () => {
      this.reset()
    })
  }

  toggle() {
    if (this.audio.paused) {
      this.play()
    } else {
      this.pause()
    }
  }

  play() {
    this.audio.play()

    this.buttonTarget.classList.add("is-playing")
    this.iconTarget.textContent = "❚❚"
    this.labelTarget.textContent = "Pause"
  }

  pause() {
    this.audio.pause()

    this.buttonTarget.classList.remove("is-playing")
    this.buttonTarget.classList.add("is-paused")

    this.iconTarget.textContent = "▶"
    this.labelTarget.textContent = "Resume"
  }

  reset() {
    this.audio.currentTime = 0

    this.buttonTarget.classList.remove("is-playing", "is-paused")

    this.iconTarget.textContent = "▶"
    this.labelTarget.textContent = "Listen"
  }
}
