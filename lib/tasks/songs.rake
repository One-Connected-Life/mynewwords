namespace :songs do
  desc "Generate study content (words + conjugations + sentences) for catalogue songs → db/songs/<slug>.json"
  task :generate, [:slug] => :environment do |_t, args|
    slugs = args[:slug].present? ? [args[:slug]] : SongCatalog::SONGS.map { |s| s[:slug] }
    SongCatalog::CONTENT_DIR.mkpath

    slugs.each do |slug|
      meta = SongCatalog.meta(slug) or abort "Unknown song slug: #{slug}"
      puts "→ #{meta[:title]} — #{meta[:artist]} (#{meta[:year]})"
      content = SongDeckGenerator.new(title: meta[:title], artist: meta[:artist], year: meta[:year]).call

      verbs = content["words"].count { |w| w["verb"] }
      out = { "title" => meta[:title], "artist" => meta[:artist], "year" => meta[:year] }.merge(content)
      path = SongCatalog::CONTENT_DIR.join("#{slug}.json")
      path.write(JSON.pretty_generate(out) + "\n")
      puts "  #{content['words'].size} words (#{verbs} verbs) + #{content['sentences'].size} sentences → #{path}"
    end
  end

  desc "Print catalogue totals (words/verbs/sentences per song + grand total)"
  task counts: :environment do
    grand = Hash.new(0)
    SongCatalog.all.each do |s|
      puts format("%-22s %2d words  %2d verbs  %2d sentences", s.title, s.word_count, s.verb_count, s.sentence_count)
      grand[:words] += s.word_count; grand[:verbs] += s.verb_count; grand[:sentences] += s.sentence_count
    end
    puts "-" * 56
    puts format("%-22s %2d words  %2d verbs  %2d sentences  = %d cards",
                "TOTAL (#{SongCatalog.all.size} songs)", grand[:words], grand[:verbs], grand[:sentences],
                grand[:words] + grand[:sentences])
  end

  desc "Add all catalogue songs to a user's account (USER=email or id) for testing"
  task :seed, [:user] => :environment do |_t, args|
    ident = args[:user] || ENV["USER_EMAIL"] || ENV["USER"]
    user = User.find_by(email_address: ident) || User.find_by(id: ident) || User.first
    abort "No user found" unless user
    SongCatalog.all.each do |song|
      deck = Deck.build_song(user, song)
      puts "✓ #{song.title} → deck ##{deck.id} (#{deck.terms.count} terms) for #{user.email_address}"
    end
  end
end
