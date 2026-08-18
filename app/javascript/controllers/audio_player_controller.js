import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  play() {
    if (!this.audio) {
      this.audio = new Audio(this.urlValue)
    }
    this.audio.play()
  }
}
