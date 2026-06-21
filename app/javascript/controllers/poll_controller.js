import { Controller } from "@hotwired/stimulus"

// Gentle auto-refresh while something is generating in the background.
// A Turbo "replace" visit keeps scroll position and skips the white flash of a
// hard <meta http-equiv="refresh"> — much nicer on a phone mid-scroll. (#5 UX)
export default class extends Controller {
  static values = { interval: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => {
      if (window.Turbo) window.Turbo.visit(window.location.href, { action: "replace" })
      else window.location.reload()
    }, this.intervalValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
