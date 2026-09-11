import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["intro", "reading", "quiz", "timer"]
  static values = { attemptUrl: String }

  connect() {
    this.startedAt = null
    this.timerInterval = null
  }

  disconnect() {
    this.stopTimer()
  }

  start() {
    this.startedAt = performance.now()
    this.introTarget.hidden = true
    this.readingTarget.hidden = false
    this.startTimer()
  }

  finish() {
    this.durationMs = Math.round(performance.now() - this.startedAt)
    this.stopTimer()
    this.readingTarget.hidden = true
    this.quizTarget.hidden = false
  }

  submit() {
    const answers = Array.from(this.quizTarget.querySelectorAll("fieldset")).map((field) => {
      const checked = field.querySelector("input:checked")
      return checked ? parseInt(checked.value, 10) : -1
    })

    if (answers.some((answer) => answer < 0)) return

    const token = document.querySelector('meta[name="csrf-token"]')

    fetch(this.attemptUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": token ? token.content : ""
      },
      body: JSON.stringify({ answers: answers, duration_ms: this.durationMs })
    })
      .then((response) => response.text())
      .then((html) => window.Turbo.renderStreamMessage(html))
      .catch(() => window.Turbo.visit(window.location.href, { action: "replace" }))
  }

  private

  startTimer() {
    this.timerInterval = setInterval(() => {
      const elapsed = (performance.now() - this.startedAt) / 1000
      this.timerTarget.textContent = elapsed.toFixed(1)
    }, 100)
  }

  stopTimer() {
    if (this.timerInterval) clearInterval(this.timerInterval)
    this.timerInterval = null
  }
}
