require "rails_helper"

RSpec.describe "Songs", type: :request do
  let(:user) { create(:user, target_language: "nl", source_language: "en") }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  before { sign_in(user) }

  it "lists the catalogue" do
    get songs_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Het Dorp")
  end

  it "turns a song into a drillable deck and redirects to the drill" do
    slug = SongCatalog::SONGS.first[:slug]
    expect { post add_song_path(slug: slug) }.to change { user.decks.count }.by(1)

    deck = user.decks.order(:created_at).last
    expect(deck).to be_song
    expect(deck.terms.count).to be > 10
    expect(response).to redirect_to(play_path(deck: deck.slug, from: "nl", to: "en"))
  end

  it "rejects an unknown song" do
    post add_song_path(slug: "no-such-song")
    expect(response).to redirect_to(songs_path)
  end
end
