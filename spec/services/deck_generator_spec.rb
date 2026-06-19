require "rails_helper"

RSpec.describe DeckGenerator do
  def canned(words)
    { "content" => [{ "type" => "text", "text" => JSON.generate(words) }] }
  end

  it "persists words in the user's target+source languages, stripping doubled articles" do
    user = create(:user, target_language: "fr", source_language: "en")
    deck = create(:deck, user: user, topic: "cooking", status: "pending")

    allow_any_instance_of(DeckGenerator).to receive(:post_message).and_return(canned([
      { "target" => "la cuisine", "article" => "la", "source" => "kitchen" },
      { "target" => "couteau", "article" => "le", "source" => "knife" },
      { "target" => "", "article" => nil, "source" => "skip me" }
    ]))

    DeckGenerator.new(deck).call
    deck.reload

    expect(deck.status).to eq("ready")
    expect(deck.terms.count).to eq(2) # blank target skipped

    cuisine = deck.terms.order(:position).first.translation("fr")
    expect(cuisine.text).to eq("cuisine")          # "la " stripped from the bare word
    expect(cuisine.with_article).to eq("la cuisine")
    expect(deck.terms.order(:position).first.translation("en").text).to eq("kitchen")
  end

  it "marks the deck failed and re-raises on API error" do
    deck = create(:deck, status: "pending")
    allow_any_instance_of(DeckGenerator).to receive(:post_message).and_raise(DeckGenerator::Error, "boom")

    expect { DeckGenerator.new(deck).call }.to raise_error(DeckGenerator::Error)
    expect(deck.reload.status).to eq("failed")
  end
end
