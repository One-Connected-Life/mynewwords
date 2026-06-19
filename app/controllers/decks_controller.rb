class DecksController < ApplicationController
  def new
    @deck = current_user.decks.new
  end

  def create
    unless current_user.can_generate?
      redirect_to new_deck_path, alert: "You've reached your deck-generation limit (#{User::GENERATION_CAP})."
      return
    end

    topic = params.require(:deck).permit(:topic)[:topic].to_s.strip
    if topic.blank?
      redirect_to new_deck_path, alert: "Tell me a topic to build a deck from."
      return
    end

    deck = current_user.decks.create!(
      name: topic.titleize,
      topic: topic,
      status: "pending",
      position: (current_user.decks.maximum(:position) || -1) + 1
    )
    current_user.increment!(:generations_count)
    GenerateDeckJob.perform_later(deck)

    redirect_to root_path, notice: "Building your “#{deck.name}” deck — it'll appear in a moment."
  end

  def destroy
    current_user.decks.find(params[:id]).destroy
    redirect_to root_path, notice: "Deck removed."
  end
end
