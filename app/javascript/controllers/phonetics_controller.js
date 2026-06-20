import { Controller } from "@hotwired/stimulus"

// Production phonetics controller.
// Manages the translit toggle for non-Latin script words (Russian etc.).
// IPA is always shown. Translit is hidden by default and toggled via the "abc" button.
// Preference is sticky via localStorage ("phonetics-translit": "1" = show).
//
// Targets:
//   ipaLine      — the IPA text element (always visible)
//   translitLine — the romanization line (non-Latin only, toggleable)
//   translitBtn  — the "abc" toggle button (non-Latin only)
//
// Values:
//   hasTranslit  — Boolean, true when a translit line is present in this card
export default class extends Controller {
  static targets = ["ipaLine", "translitLine", "translitBtn"]
  static values = { hasTranslit: Boolean }

  connect() {
    if (!this.hasTranslitValue) return
    // Restore preference: show translit if the user previously enabled it.
    if (localStorage.getItem("phonetics-translit") === "1") {
      this._showTranslit()
    }
  }

  toggleTranslit() {
    const showing = this.hasTranslitLineTarget && !this.translitLineTarget.classList.contains("hidden")
    if (showing) {
      this._hideTranslit()
    } else {
      this._showTranslit()
    }
  }

  _showTranslit() {
    if (this.hasTranslitLineTarget) this.translitLineTarget.classList.remove("hidden")
    if (this.hasTranslitBtnTarget) this.translitBtnTarget.textContent = "ipa"
    localStorage.setItem("phonetics-translit", "1")
  }

  _hideTranslit() {
    if (this.hasTranslitLineTarget) this.translitLineTarget.classList.add("hidden")
    if (this.hasTranslitBtnTarget) this.translitBtnTarget.textContent = "abc"
    localStorage.setItem("phonetics-translit", "0")
  }
}
