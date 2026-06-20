require "rails_helper"

RSpec.describe "DeckGenerator — phonetics" do
  def canned(words)
    { "content" => [{ "type" => "text", "text" => JSON.generate(words) }] }
  end

  context "Latin-script target language (French)" do
    it "stores IPA but no translit on the target translation" do
      user = create(:user, target_language: "fr", source_language: "en")
      deck = create(:deck, user: user, topic: "food", status: "pending")

      allow_any_instance_of(DeckGenerator).to receive(:post_message).and_return(canned([
        { "target" => "pain", "article" => "le", "source" => "bread", "ipa" => "pɛ̃", "translit" => nil },
      ]))

      DeckGenerator.new(deck).call
      t = deck.reload.terms.first.translation("fr")

      expect(t.ipa).to eq("pɛ̃")
      expect(t.translit).to be_nil
      expect(t.non_latin?).to be false
    end

    it "skips phonetics when the API returns a blank ipa" do
      user = create(:user, target_language: "fr", source_language: "en")
      deck = create(:deck, user: user, topic: "food", status: "pending")

      allow_any_instance_of(DeckGenerator).to receive(:post_message).and_return(canned([
        { "target" => "pain", "article" => "le", "source" => "bread", "ipa" => "", "translit" => nil },
      ]))

      DeckGenerator.new(deck).call
      t = deck.reload.terms.first.translation("fr")

      expect(t.phonetics).to be_nil
    end
  end

  context "non-Latin target language (Russian)" do
    it "stores IPA and translit on the target translation" do
      user = create(:user, target_language: "ru", source_language: "en")
      deck = create(:deck, user: user, topic: "food", status: "pending")

      allow_any_instance_of(DeckGenerator).to receive(:post_message).and_return(canned([
        { "target" => "хлеб", "article" => nil, "source" => "bread", "ipa" => "xlʲep", "translit" => "khleb" },
      ]))

      DeckGenerator.new(deck).call
      t = deck.reload.terms.first.translation("ru")

      expect(t.ipa).to eq("xlʲep")
      expect(t.translit).to eq("khleb")
      expect(t.non_latin?).to be true
    end
  end

  it "does not store phonetics on the source (English) translation" do
    user = create(:user, target_language: "nl", source_language: "en")
    deck = create(:deck, user: user, topic: "food", status: "pending")

    allow_any_instance_of(DeckGenerator).to receive(:post_message).and_return(canned([
      { "target" => "brood", "article" => "het", "source" => "bread", "ipa" => "broːt", "translit" => nil },
    ]))

    DeckGenerator.new(deck).call
    en_translation = deck.reload.terms.first.translation("en")

    expect(en_translation.phonetics).to be_nil
  end
end
