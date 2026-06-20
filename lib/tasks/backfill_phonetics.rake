require "net/http"
require "uri"
require "json"

# Backfill IPA (and transliteration for non-Latin scripts) for all existing
# translations that are the target-language word for a deck.
#
# Idempotent: skips translations that already have phonetics set.
# Processes only target-language translations (not source/English side).
#
# Usage:
#   bundle exec rails phonetics:backfill
#   bundle exec rails phonetics:backfill DRY_RUN=1   # prints plan, no writes
namespace :phonetics do
  desc "Backfill IPA (+translit for Russian) on existing translations that lack phonetics"
  task backfill: :environment do
    dry_run = ENV["DRY_RUN"] == "1"
    puts "[phonetics:backfill] dry_run=#{dry_run}"

    # Target-language translations are those whose language = the deck owner's target_language.
    missing = Translation.joins(term: { deck: :user })
                         .where(phonetics: nil)
                         .where("translations.language = users.target_language")
                         .order(:id)

    puts "[phonetics:backfill] #{missing.count} translations need phonetics"
    exit 0 if missing.count == 0

    updated = 0
    failed = 0

    missing.find_each do |translation|
      data = fetch_phonetics(translation)

      if data
        line = "  #{translation.id} (#{translation.language}) #{translation.text.inspect} → ipa=#{data["ipa"].inspect} translit=#{data["translit"].inspect}"
        if dry_run
          puts "[dry] #{line}"
        else
          translation.update_column(:phonetics, JSON.generate(data.compact))
          updated += 1
          puts "[done] #{line}"
        end
      else
        failed += 1
        puts "[skip] #{translation.id} #{translation.text.inspect} — API returned nothing"
      end

      # Be gentle: 1 request per second to avoid hammering the Anthropic API.
      sleep 1 unless dry_run
    end

    puts "[phonetics:backfill] done. updated=#{updated} failed=#{failed}"
  end
end

# Ask Claude for IPA + optional translit for a single translation.
# Returns {"ipa" => "...", "translit" => ...} or nil on error.
def fetch_phonetics(translation)
  language = Translation::LANGUAGES[translation.language]
  non_latin = Translation::NON_LATIN.include?(translation.language)
  word = translation.text

  translit_note = non_latin ?
    'Also provide "translit": a spelling-based romanization (e.g. хлеб → khleb, final б = b even though unvoiced in speech).' :
    'Set "translit" to null.'

  system = "You are a phonetics expert. Output ONLY valid JSON, no prose, no markdown."
  prompt = <<~PROMPT
    Give the IPA transcription for the #{language} word or phrase: #{word.inspect}

    Return exactly one JSON object with two keys:
      {"ipa": "<IPA without surrounding slashes or brackets>", "translit": <null or string>}
    #{translit_note}
  PROMPT

  response = anthropic_post(system, prompt)
  text = response.dig("content", 0, "text").to_s.strip
               .sub(/\A```(?:json)?\s*/, "").sub(/\s*```\z/, "").strip
  data = JSON.parse(text)
  data.slice("ipa", "translit")
rescue StandardError => e
  Rails.logger.error("[phonetics:backfill] #{e.class}: #{e.message} for translation #{translation.id}")
  nil
end

def anthropic_post(system, prompt)
  uri = URI("https://api.anthropic.com/v1/messages")
  req = Net::HTTP::Post.new(uri)
  req["x-api-key"] = ENV.fetch("ANTHROPIC_API_KEY") { raise "ANTHROPIC_API_KEY not set" }
  req["anthropic-version"] = "2023-06-01"
  req["content-type"] = "application/json"
  req.body = JSON.generate(
    model: "claude-haiku-4-5-20251001",
    max_tokens: 200,
    system: system,
    messages: [{ role: "user", content: prompt }]
  )
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30, open_timeout: 10) { |h| h.request(req) }
  raise "Anthropic API #{res.code}: #{res.body.to_s.first(200)}" unless res.code.to_i == 200
  JSON.parse(res.body)
end
