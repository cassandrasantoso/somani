import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "answer", "grades", "reveal", "progress"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.show()
  }

  reveal() {
    this.answerTargets[this.indexValue].hidden = false
    this.gradesTargets[this.indexValue].hidden = false
    this.revealTargets[this.indexValue].hidden = true
  }

  async grade(event) {
    const card = this.cardTargets[this.indexValue]
    const last = this.indexValue === this.cardTargets.length - 1

    if (last) {
      this.progressTarget.textContent = "Saving…"
      await this.submit(card.dataset.quizReviewUrl, event.params.grade)
      window.Turbo.visit(window.location.href, { action: "replace" })
      return
    }

    this.submit(card.dataset.quizReviewUrl, event.params.grade)
    this.indexValue += 1
    this.show()
  }

  private

  show() {
    this.cardTargets.forEach((card, i) => {
      card.hidden = i !== this.indexValue
    })

    this.progressTarget.textContent = `${this.indexValue + 1} / ${this.cardTargets.length}`
  }

  submit(url, grade) {
    const token = document.querySelector('meta[name="csrf-token"]')

    return fetch(url, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token ? token.content : ""
      },
      body: JSON.stringify({ grade: grade })
    }).catch(() => {})
  }
}
