class GenerateDeckJob < ApplicationJob
  queue_as :default

  def perform(deck)
    DeckGenerator.new(deck).call
  end
end
