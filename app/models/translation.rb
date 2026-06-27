class Translation < ApplicationRecord
  # ISO 639-1 code => display name. Adding a language is a data change, not a migration.
  LANGUAGES = {
    "en" => "English",
    "nl" => "Dutch",
    "es" => "Spanish",
    "fr" => "French",
    "it" => "Italian",
    "ro" => "Romanian",
    "ru" => "Russian",
  }.freeze

  # Languages currently drillable in the UI. The rest ride along as dormant data
  # until we verify them and switch them on.
  SURFACED = %w[nl en].freeze

  # Languages that use non-Latin scripts — these get a transliteration alongside IPA.
  NON_LATIN = %w[ru].freeze

  belongs_to :term

  # phonetics column stores { "ipa" => "...", "translit" => "..." } as JSON.
  # translit is only present for NON_LATIN languages.
  def phonetics_data
    return {} if phonetics.blank?
    JSON.parse(phonetics)
  rescue JSON::ParserError
    {}
  end

  def ipa = phonetics_data["ipa"]
  def translit = phonetics_data["translit"]

  # conjugation column stores a verb's table as JSON:
  #   { "infinitive", "present" => {"ik"=>..., ...}, "past" => {...}, "future" => {...} }
  # Empty hash for non-verbs (or unparseable data).
  def conjugation_data
    return {} if conjugation.blank?
    JSON.parse(conjugation)
  rescue JSON::ParserError
    {}
  end

  def verb? = conjugation.present?

  def non_latin?
    NON_LATIN.include?(language)
  end

  validates :language, presence: true, inclusion: { in: LANGUAGES.keys }
  validates :text, presence: true
  validates :language, uniqueness: { scope: :term_id }

  def language_name
    LANGUAGES[language]
  end

  # Extra acceptable answers beyond the primary text (pipe-separated).
  def alternate_list
    alternates.to_s.split("|").map(&:strip).reject(&:blank?)
  end

  # Everything that should be graded correct when this translation is the answer.
  def accepted_answers
    [text, *alternate_list]
  end

  # "het brood" when an article is set, otherwise just the word.
  # Elided articles (French l', d') attach with no space: "l'ingrédient".
  def with_article
    return text if article.blank?

    separator = article.end_with?("'") ? "" : " "
    "#{article}#{separator}#{text}"
  end
end
