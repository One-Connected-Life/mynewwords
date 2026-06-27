# The curated set of songs a learner can turn into a deck. Metadata (title/artist/year/
# listen link) lives here in code; the generated study CONTENT (words, conjugations,
# example sentences) lives in db/songs/<slug>.json so a deck builds instantly and offline
# — no API call, no per-build cost, deterministic. Content is produced once by
# SongDeckGenerator (rake songs:generate) and committed.
#
# Listen links are plain youtube.com watch URLs (universally playable; open fine in
# YouTube Music too). No verbatim lyrics are stored anywhere in the repo.
class SongCatalog
  Song = Data.define(:slug, :title, :artist, :year, :listen_url, :words, :sentences) do
    def name = "🎵 #{title}"
    def subtitle = "#{artist} · #{year}"
    def word_count = words.size
    def sentence_count = sentences.size
    def verb_count = words.count { |w| w["verb"] }
  end

  # ── The catalogue: older, beloved Dutch classics with a good vocab spread. ──
  SONGS = [
    {
      slug: "het-dorp", title: "Het Dorp", artist: "Wim Sonneveld", year: 1974,
      listen_url: "https://www.youtube.com/watch?v=C8Ff5OEUzd8",
    },
    {
      slug: "zij-gelooft-in-mij", title: "Zij gelooft in mij", artist: "André Hazes", year: 1981,
      listen_url: "https://www.youtube.com/watch?v=VAc9opfAEYQ",
    },
    {
      slug: "het-is-een-nacht", title: "'t Is een nacht", artist: "Guus Meeuwis", year: 1995,
      listen_url: "https://www.youtube.com/watch?v=eIX2SZW4Ih8",
    },
  ].freeze

  CONTENT_DIR = Rails.root.join("db", "songs")

  class << self
    # All songs that have generated content committed (drillable today).
    def all
      SONGS.filter_map { |meta| load(meta[:slug]) }
    end

    def find(slug)
      load(slug)
    end

    # The raw metadata for a slug (no content) — used by the generator rake task.
    def meta(slug)
      SONGS.find { |s| s[:slug] == slug.to_s }
    end

    private

    def load(slug)
      meta = self.meta(slug)
      return nil unless meta

      path = CONTENT_DIR.join("#{slug}.json")
      return nil unless path.exist?

      content = JSON.parse(path.read)
      Song.new(
        slug: meta[:slug], title: meta[:title], artist: meta[:artist],
        year: meta[:year], listen_url: meta[:listen_url],
        words: Array(content["words"]), sentences: Array(content["sentences"]),
      )
    rescue JSON::ParserError
      nil
    end
  end
end
