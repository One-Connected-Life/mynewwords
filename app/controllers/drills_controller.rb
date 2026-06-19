class DrillsController < ApplicationController
  def home
    @decks = Deck.includes(:terms).order(:position)
  end

  def play
    @deck = Deck.find_by!(slug: params[:deck])
    @from = surfaced_lang(params[:from], "nl")
    @to   = surfaced_lang(params[:to], "en")

    @cards = @deck.terms.includes(:translations).filter_map do |term|
      prompt = term.translation(@from)
      answer = term.translation(@to)
      next unless prompt && answer

      {
        prompt: prompt.with_article,
        answer: answer.text,
        answer_article: answer.article,
      }
    end
  end

  private

  # Only let the surfaced (verified) languages drive the drill; fall back otherwise.
  def surfaced_lang(value, fallback)
    Translation::SURFACED.include?(value) ? value : fallback
  end
end
