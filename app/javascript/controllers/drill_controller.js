import { Controller } from "@hotwired/stimulus"

// Snappy in-browser drill: prompt -> type -> Enter grades -> Enter again advances.
// Cards come pre-rendered as JSON so there is no server round-trip per word.
export default class extends Controller {
  static targets = ["prompt", "input", "feedback", "answer", "progress", "score", "card", "summary", "summaryText"]
  static values = { cards: Array }

  connect() {
    this.cards = this.shuffle([...this.cardsValue])
    this.index = 0
    this.correct = 0
    this.state = "answering"
    this.render()
  }

  // Enter does double duty: grade, then advance.
  keydown(event) {
    if (event.key !== "Enter") return
    event.preventDefault()
    this.state === "answering" ? this.grade() : this.next()
  }

  grade() {
    const card = this.cards[this.index]
    const ok = this.normalize(this.inputTarget.value) === this.normalize(card.answer)
    if (ok) this.correct++

    const full = card.answer_article ? `${card.answer_article} ${card.answer}` : card.answer
    this.feedbackTarget.textContent = ok ? "✓ correct" : "✗ not quite"
    this.feedbackTarget.className = ok
      ? "text-emerald-500 font-medium"
      : "text-rose-500 font-medium"
    this.answerTarget.textContent = full
    this.answerTarget.classList.remove("invisible")
    this.inputTarget.disabled = true
    this.state = "reveal"
    this.updateScore()
  }

  next() {
    this.index++
    if (this.index >= this.cards.length) return this.finish()
    this.state = "answering"
    this.render()
  }

  render() {
    const card = this.cards[this.index]
    this.promptTarget.textContent = card.prompt
    this.feedbackTarget.textContent = ""
    this.answerTarget.textContent = ""
    this.answerTarget.classList.add("invisible")
    this.inputTarget.value = ""
    this.inputTarget.disabled = false
    this.inputTarget.focus()
    this.progressTarget.textContent = `${this.index + 1} / ${this.cards.length}`
    this.updateScore()
  }

  finish() {
    this.cardTarget.classList.add("hidden")
    this.summaryTarget.classList.remove("hidden")
    const pct = Math.round((this.correct / this.cards.length) * 100)
    this.summaryTextTarget.textContent = `${this.correct} / ${this.cards.length} correct (${pct}%)`
  }

  restart() {
    this.connect()
    this.cardTarget.classList.remove("hidden")
    this.summaryTarget.classList.add("hidden")
  }

  updateScore() {
    this.scoreTarget.textContent = `${this.correct} correct`
  }

  // Forgiving compare: case/whitespace/diacritics-insensitive, ignores leading articles.
  normalize(value) {
    return (value || "")
      .toLowerCase()
      .normalize("NFD").replace(/[̀-ͯ]/g, "")
      .replace(/^(de|het|een|the|a|an)\s+/, "")
      .replace(/\s+/g, " ")
      .trim()
  }

  shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[array[i], array[j]] = [array[j], array[i]]
    }
    return array
  }
}
