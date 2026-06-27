# Browse the song catalogue and turn a song into a drillable deck. Content is static
# (db/songs/*.json), so "Add" is instant — no background job, no API call.
class SongsController < ApplicationController
  def index
    @songs = SongCatalog.all
    # listen_url → the user's existing deck for that song (if any), so we can show
    # "Drill" instead of "Add deck".
    @owned = current_user.decks.where.not(listen_url: nil).index_by(&:listen_url)
  end

  def create
    song = SongCatalog.find(params[:slug])
    redirect_to(songs_path, alert: "That song isn't available.") and return unless song

    deck = Deck.build_song(current_user, song)
    redirect_to play_path(deck: deck.slug, from: current_user.target_language, to: current_user.source_language),
      notice: "“#{song.title}” added — #{deck.terms.count} cards. Veel plezier!"
  end
end
