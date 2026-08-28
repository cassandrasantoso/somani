import { Controller } from "@hotwired/stimulus"

// Uploads take a while server-side (Cloudinary + AI text extraction), so the
// percentage here is a smooth simulated climb rather than real byte progress -
// it eases up to 90% and only jumps to 100% once the response actually comes back.
const MAX_SIMULATED_PERCENT = 90
const TICK_MS = 200

export default class extends Controller {
  static targets = ["overlay", "percent", "barFill"]

  connect() {
    this.percent = 0
    this.timer = null
  }

  showLoading() {
    this.percent = 0
    this.updateDisplay()
    this.overlayTarget.hidden = false

    this.timer = setInterval(() => {
      const remaining = MAX_SIMULATED_PERCENT - this.percent
      this.percent += Math.max(remaining * 0.08, 0.3)
      if (this.percent >= MAX_SIMULATED_PERCENT) {
        this.percent = MAX_SIMULATED_PERCENT
        clearInterval(this.timer)
      }
      this.updateDisplay()
    }, TICK_MS)
  }

  hideLoading() {
    if (this.timer) clearInterval(this.timer)
    if (!this.hasOverlayTarget || this.overlayTarget.hidden) return

    this.percent = 100
    this.updateDisplay()
    this.overlayTarget.hidden = true
  }

  updateDisplay() {
    const rounded = Math.round(this.percent)
    this.percentTarget.textContent = `${rounded}%`
    this.barFillTarget.style.width = `${rounded}%`
  }
}
