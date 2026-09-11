import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (sessionStorage.getItem("timezone-set")) return

    const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
    const token = document.querySelector('meta[name="csrf-token"]')

    sessionStorage.setItem("timezone-set", "1")

    if (zone && token) {
      fetch("/timezone", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token.content
        },
        body: JSON.stringify({ time_zone: zone })
      }).catch(() => {})
    }
  }
}
