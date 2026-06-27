require "rails_helper"

RSpec.describe "Song decks" do
  let(:user) { create(:user, target_language: "nl", source_language: "en") }

  # A small in-memory song so the spec doesn't depend on db/songs/*.json content.
  let(:song) do
    SongCatalog::Song.new(
      slug: "test-song", title: "Test Song", artist: "Tester", year: 1999,
      listen_url: "https://example.com/listen",
      words: [
        { "target" => "dorp", "source" => "village", "article" => "het",
          "etymology" => "Old Dutch thorp", "mnemonic" => nil, "ipa" => "dɔrp", "verb" => false, "conjugation" => nil },
        { "target" => "lopen", "source" => "to walk", "article" => nil,
          "etymology" => nil, "mnemonic" => nil, "ipa" => "ˈloːpə(n)", "verb" => true,
          "conjugation" => {
            "infinitive" => "lopen",
            "present" => { "ik" => "loop", "jij" => "loopt", "hij" => "loopt", "wij" => "lopen", "jullie" => "lopen", "zij" => "lopen" },
            "past"    => { "ik" => "liep", "jij" => "liep", "hij" => "liep", "wij" => "liepen", "jullie" => "liepen", "zij" => "liepen" },
            "future"  => { "ik" => "zal lopen", "jij" => "zult lopen", "hij" => "zal lopen", "wij" => "zullen lopen", "jullie" => "zullen lopen", "zij" => "zullen lopen" },
          } },
      ],
      sentences: [
        { "nl" => "Ik loop door het dorp.", "en" => "I walk through the village." },
      ],
    )
  end

  describe "Deck.build_song" do
    it "creates a drillable deck with words, a verb conjugation table, and sentences" do
      deck = Deck.build_song(user, song)

      expect(deck).to be_persisted
      expect(deck.status).to eq("ready")
      expect(deck.listen_url).to eq("https://example.com/listen")
      expect(deck.artist).to eq("Tester")
      expect(deck).to be_song

      words = deck.terms.where(kind: "word")
      expect(words.count).to eq(2)

      verb_nl = deck.terms.flat_map(&:translations).find { |t| t.language == "nl" && t.text == "lopen" }
      expect(verb_nl).to be_verb
      expect(verb_nl.conjugation_data.dig("past", "wij")).to eq("liepen")

      noun_nl = deck.terms.flat_map(&:translations).find { |t| t.text == "dorp" }
      expect(noun_nl).not_to be_verb
      expect(noun_nl.article).to eq("het")
      expect(noun_nl.ipa).to eq("dɔrp")

      sentence = deck.terms.find_by(kind: "sentence")
      expect(sentence.translation("nl").text).to eq("Ik loop door het dorp.")
      expect(sentence.translation("en").text).to eq("I walk through the village.")
    end

    it "is idempotent per song — re-adding returns the same deck, no duplicate terms" do
      first = Deck.build_song(user, song)
      second = Deck.build_song(user, song)

      expect(second.id).to eq(first.id)
      expect(user.decks.where(listen_url: song.listen_url).count).to eq(1)
      expect(first.terms.where(kind: "word").count).to eq(2)
    end
  end

  describe "SongCatalog (committed content)" do
    it "loads every catalogue song with real words, verbs, and sentences" do
      SongCatalog.all.each do |s|
        expect(s.word_count).to be > 10, "#{s.title} has too few words"
        expect(s.verb_count).to be > 0, "#{s.title} has no conjugated verbs"
        expect(s.sentence_count).to be > 0, "#{s.title} has no sentences"
        s.words.select { |w| w["verb"] }.each do |v|
          expect(v.dig("conjugation", "present", "ik")).to be_present, "#{v['target']} missing present tense"
          expect(v.dig("conjugation", "future", "ik")).to match(/zal|zult|zullen/), "#{v['target']} bad future"
        end
      end
    end
  end
end
