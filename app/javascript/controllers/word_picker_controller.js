import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["surface", "reading", "meaning", "level", "times"]
  static values = { alreadySaved: Array }

  capture() {
    const selected = window.getSelection().toString().trim()
    if (!selected) return

    this.surfaceTarget.value = selected
    this.checkDuplicate(selected)
  }

  // Triggered by clicking a highlighted (seed-matched) word.
  // Fills all four fields from data already known in the database.
  selectMatch({ params }) {
    this.surfaceTarget.value = params.surface
    this.readingTarget.value = params.reading
    this.meaningTarget.value = params.meaning
    this.levelTarget.value = params.level
    this.timesTarget.value = "1"

    this.checkDuplicate(params.surface)
  }

  // Triggered by the modal itself (see the data-action on #exampleModal),
  // so it works for any trigger button anywhere on the page — including the
  // "Edit" button on an already-saved word, which lives outside this
  // controller's own markup. Ignores triggers (like the JLPT <mark> matches)
  // that don't carry this data, since those already fill the form themselves
  // via selectMatch on click, before this event fires.
  prefill(event) {
    const button = event.relatedTarget
    if (!button || !button.dataset.surface) return

    this.surfaceTarget.value = button.dataset.surface
    this.readingTarget.value = button.dataset.reading || ""
    this.meaningTarget.value = button.dataset.meaning || ""
    this.levelTarget.value = button.dataset.level || ""
    this.timesTarget.value = button.dataset.times || "1"
    this.surfaceTarget.setCustomValidity("")
  }

  playPronunciation() {
    const text = this.readingTarget.value.trim()
    if (!text) return

    new Audio(`/pronunciation?text=${encodeURIComponent(text)}`).play()
  }

  checkDuplicate(surface) {
    if (this.alreadySavedValue.includes(surface)) {
      this.surfaceTarget.setCustomValidity("You've already saved this word.")
    } else {
      this.surfaceTarget.setCustomValidity("")
    }
    this.surfaceTarget.reportValidity()
  }

  // The turbo_stream response replaces this whole element, including the
  // open modal, without ever running Bootstrap's own hide() cleanup. That
  // leaves the backdrop (appended to <body>, outside this element) and
  // <body>'s modal-open styling stuck behind. Bootstrap's own hide() is
  // animated and silently no-ops if called before its show transition has
  // finished (still mid-open), so clean up its side effects directly
  // instead of relying on that timing.
  closeModal(event) {
    if (!event.detail.success) return

    document.body.classList.remove("modal-open")
    document.body.style.removeProperty("overflow")
    document.body.style.removeProperty("padding-right")
    document.querySelectorAll(".modal-backdrop").forEach(backdrop => backdrop.remove())
  }
}
