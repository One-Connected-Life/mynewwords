class DrillsController < ApplicationController
  def home
    @decks = Deck.includes(:terms).order(:position)
  end

  def play
    if params[:deck].present? && params[:deck] != "all"
      @deck = Deck.find_by!(slug: params[:deck])
      terms = @deck.terms
    else
      terms = Term.order(:deck_id, :position)
    end

    @title     = @deck&.name || "All words"
    @deck_slug = @deck&.slug || "all"
    @from = surfaced_lang(params[:from], "nl")
    @to   = surfaced_lang(params[:to], "en")

    @cards = terms.includes(:translations).filter_map do |term|
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
