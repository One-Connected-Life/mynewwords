class StatsController < ApplicationController
  def index
    @words = Term.where(kind: "word").includes(:translations).to_a

    # [term_id, from, to] => { correct:, wrong:, latest_correct: }
    @summary = Hash.new { |h, k| h[k] = { correct: 0, wrong: 0, latest_correct: nil } }
    Attempt.order(:id).find_each do |a|
      s = @summary[[a.term_id, a.from_language, a.to_language]]
      a.correct ? s[:correct] += 1 : s[:wrong] += 1
      s[:latest_correct] = a.correct
    end

    @resting = Attempt.resting_term_ids(from: "nl", to: "en").to_set

    # Most-drilled first (by NL->EN activity), then alphabetical.
    @words.sort_by! do |t|
      s = @summary[[t.id, "nl", "en"]]
      [-(s[:correct] + s[:wrong]), t.translation("en")&.text.to_s]
    end

    @totals = {
      attempts: Attempt.count,
      correct: Attempt.where(correct: true).count,
      owned: @words.count { |t| @summary[[t.id, "nl", "en"]][:correct] >= 2 },
    }
  end

  helper_method :word_status
  def word_status(term)
    s = @summary[[term.id, "nl", "en"]]
    return "new" if s[:correct] + s[:wrong] == 0
    return "owned · resting" if @resting.include?(term.id)
    return "owned · due" if s[:correct] >= 2
    return "missed" if s[:latest_correct] == false
    "learning #{s[:correct]}/2"
  end
end
