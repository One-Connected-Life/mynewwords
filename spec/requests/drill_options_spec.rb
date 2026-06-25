require "rails_helper"

# Finding A: the drill options cluster moved off the play screen into Settings,
# and the options are now persisted per-user (not session/localStorage).
RSpec.describe "Drill options relocation (Finding A)", type: :request do
  let(:user) { create(:user, target_language: "nl", source_language: "en") }

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  before do
    sign_in(user)
    deck = create(:deck, user: user, status: "ready")
    term = create(:term, deck: deck, kind: "word", reviewed: true)
    create(:translation, term: term, language: "nl", text: "brood")
    create(:translation, term: term, language: "en", text: "bread")
  end

  it "no longer renders the old top option cluster on the drill screen" do
    get play_path
    expect(response).to have_http_status(:ok)
    # The old toggle labels lived in the drill header; they belong in Settings now.
    expect(response.body).not_to include("easy cognates: shown")
    expect(response.body).not_to include("mastered: shown")
    expect(response.body).not_to include("auto-play prompt")
    expect(response.body).not_to include("read answer if wrong")
  end

  it "carries the user's saved autoplay prefs into the drill controller dataset" do
    user.update!(autoplay_prompt: true, autoplay_wrong: true)
    get play_path
    expect(response.body).to include('data-drill-autoplay-prompt-value="true"')
    expect(response.body).to include('data-drill-autoplay-wrong-value="true"')
  end

  it "still honors a skip_easy URL param by persisting it to the user" do
    expect { get play_path(skip_easy: "1") }
      .to change { user.reload.skip_easy? }.from(false).to(true)
  end
end
