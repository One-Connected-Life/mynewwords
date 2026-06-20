require "rails_helper"

RSpec.describe Translation, type: :model do
  describe "#phonetics_data" do
    it "returns an empty hash when phonetics is nil" do
      t = build(:translation, phonetics: nil)
      expect(t.phonetics_data).to eq({})
    end

    it "parses JSON stored in the phonetics column" do
      t = build(:translation, phonetics: '{"ipa":"xlʲep","translit":"khleb"}')
      expect(t.phonetics_data).to eq("ipa" => "xlʲep", "translit" => "khleb")
    end

    it "returns an empty hash on malformed JSON" do
      t = build(:translation, phonetics: "not-json")
      expect(t.phonetics_data).to eq({})
    end
  end

  describe "#ipa" do
    it "returns nil when no phonetics" do
      expect(build(:translation, phonetics: nil).ipa).to be_nil
    end

    it "returns the IPA string" do
      t = build(:translation, phonetics: '{"ipa":"broːt"}')
      expect(t.ipa).to eq("broːt")
    end
  end

  describe "#translit" do
    it "returns nil when no translit in phonetics" do
      t = build(:translation, phonetics: '{"ipa":"broːt"}')
      expect(t.translit).to be_nil
    end

    it "returns the translit string when present" do
      t = build(:translation, phonetics: '{"ipa":"xlʲep","translit":"khleb"}')
      expect(t.translit).to eq("khleb")
    end
  end

  describe "#non_latin?" do
    it "is false for Latin-script languages" do
      expect(build(:translation, language: "nl").non_latin?).to be false
      expect(build(:translation, language: "fr").non_latin?).to be false
      expect(build(:translation, language: "en").non_latin?).to be false
    end

    it "is true for Russian" do
      expect(build(:translation, language: "ru").non_latin?).to be true
    end
  end
end
