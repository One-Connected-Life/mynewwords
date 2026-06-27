class AddSongDeckSupport < ActiveRecord::Migration[8.1]
  def change
    # A song deck is a normal deck that also knows where to LISTEN to the song.
    # listen_url present ⇒ render it as a song (🎵 Listen button, artist/year header).
    add_column :decks, :listen_url, :string
    add_column :decks, :artist, :string
    add_column :decks, :year, :integer

    # Verbs carry a conjugation table (present/past/future × all pronouns) as JSON,
    # alongside the existing phonetics JSON. nil for non-verbs.
    add_column :translations, :conjugation, :text
  end
end
