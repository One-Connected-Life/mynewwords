require "net/http"
require "uri"
require "json"

# Builds the CONTENT for a "song deck" via the Anthropic Messages API: the vocabulary
# that appears in a song, verb conjugation tables, and a few original example sentences
# themed on the song. It returns a plain Hash (the same shape we persist as db/songs/*.json)
# — it does NOT touch the database. SongCatalog#load + Deck#absorb_song do the persisting.
#
# Why no verbatim lyrics: the repo is public (AGPL) and lyrics are copyrighted. Individual
# words and factual conjugation tables are not; example sentences are our own. The real
# song is one tap away via listen_url.
#
# Sonnet (not Haiku) because conjugation accuracy and natural sentences matter.
class SongDeckGenerator
  Error = Class.new(StandardError)

  MODEL    = ENV.fetch("SONG_MODEL", "claude-sonnet-4-6")
  ENDPOINT = "https://api.anthropic.com/v1/messages"
  WORDS    = 35   # target vocab size per song
  SENTENCES = 8   # original example sentences per song

  PRONOUNS = %w[ik jij hij wij jullie zij].freeze

  # song: a Hash/SongCatalog::Song with :title, :artist, :year (target lang assumed Dutch).
  def initialize(title:, artist:, year:)
    @title = title
    @artist = artist
    @year = year
  end

  # → { "words" => [...], "sentences" => [...] } ready to merge into the catalog entry.
  def call
    text = strip_fences(post_message(system_prompt, user_prompt))
    raise Error, "model returned nothing" if text.blank?
    data = JSON.parse(text)
    {
      "words"     => Array(data["words"]),
      "sentences" => Array(data["sentences"]),
    }
  rescue JSON::ParserError => e
    raise Error, "could not parse model output: #{e.message}"
  end

  private

  def system_prompt
    "You are a Dutch-language teacher building study material. Output ONLY a valid JSON " \
    "object, no prose, no markdown fences. Dutch grammar (articles, conjugations) must be " \
    "correct — learners trust it."
  end

  def user_prompt
    <<~PROMPT
      Build study material from the Dutch song "#{@title}" by #{@artist} (#{@year}).

      Do NOT reproduce the song's lyrics. Instead:

      1. WORDS: list up to #{WORDS} of the meaningful Dutch words that appear in the song
         (nouns, verbs, adjectives, useful adverbs) — the vocabulary a learner needs to
         understand it. Skip proper nouns and trivial function words (de, het, een, en, ...).
         For each word give an English translation. For NOUNS give the article (de/het).
         For VERBS give the full conjugation table (see below).

      2. SENTENCES: write #{SENTENCES} short, natural, ORIGINAL beginner Dutch sentences
         (with English) that use the song's vocabulary and evoke its themes — but are NOT
         lines from the song. Simple, everyday, grammatically correct.

      Return a JSON object:
      {
        "words": [
          {
            "target": "<Dutch word, bare — no article>",
            "source": "<English translation>",
            "article": "<de|het if a noun, else null>",
            "etymology": "<≤12-word factual origin, or null>",
            "mnemonic": "<≤12-word English memory hook, or null>",
            "ipa": "<IPA, no slashes>",
            "verb": <true|false>,
            "conjugation": <null for non-verbs, OR for verbs:
              {
                "infinitive": "<infinitive>",
                "present": { #{PRONOUNS.map { |p| %("#{p}": "<form>") }.join(", ")} },
                "past":    { #{PRONOUNS.map { |p| %("#{p}": "<form>") }.join(", ")} },
                "future":  { #{PRONOUNS.map { |p| %("#{p}": "<zal/zullen + infinitive>") }.join(", ")} }
              }>
          }
        ],
        "sentences": [ { "nl": "<Dutch>", "en": "<English>" } ]
      }

      Conjugation rules: use the pronouns ik, jij, hij, wij, jullie, zij. present = onvoltooid
      tegenwoordige tijd; past = onvoltooid verleden tijd (singular vs plural stem matters,
      e.g. ik liep / wij liepen); future = zal/zult/zullen + infinitive. Handle separable and
      irregular verbs correctly. No duplicate words. No markdown, JSON only.
    PROMPT
  end

  def strip_fences(text)
    text.to_s.strip.sub(/\A```(?:json)?\s*/, "").sub(/\s*```\z/, "").strip
  end

  def post_message(system, prompt)
    key = ENV["ANTHROPIC_API_KEY"].presence or raise(Error, "ANTHROPIC_API_KEY is not set")
    uri = URI(ENDPOINT)
    req = Net::HTTP::Post.new(uri)
    req["x-api-key"] = key
    req["anthropic-version"] = "2023-06-01"
    req["content-type"] = "application/json"
    req.body = JSON.generate(model: MODEL, max_tokens: 8000, system: system,
                             messages: [{ role: "user", content: prompt }])
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 180, open_timeout: 15) do |http|
      http.request(req)
    end
    raise Error, "Anthropic API #{res.code}: #{res.body.to_s.first(300)}" unless res.code.to_i == 200
    JSON.parse(res.body).dig("content", 0, "text").to_s
  end
end
