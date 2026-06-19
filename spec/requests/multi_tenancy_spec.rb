require "rails_helper"

RSpec.describe "Multi-tenancy isolation", type: :request do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  it "never exposes another user's word page" do
    other = create(:user)
    deck = create(:deck, user: other)
    term = create(:term, deck: deck)
    create(:translation, term: term, language: "nl", text: "geheim")

    sign_in create(:user)
    get term_path(term)
    expect(response).to have_http_status(:not_found)
  end

  it "scopes a recorded attempt to the current user" do
    me = create(:user)
    deck = create(:deck, user: me)
    term = create(:term, deck: deck)
    create(:translation, term: term, language: "nl", text: "brood")
    create(:translation, term: term, language: "en", text: "bread")
    sign_in me

    expect {
      post attempts_path, params: { term_id: term.id, from: "nl", to: "en", correct: true, given: "bread" }
    }.to change { me.attempts.count }.by(1)
    expect(response).to have_http_status(:ok)
  end

  it "won't record an attempt against another user's term" do
    other = create(:user)
    term = create(:term, deck: create(:deck, user: other))
    sign_in create(:user)

    post attempts_path, params: { term_id: term.id, from: "nl", to: "en", correct: true }
    expect(response).to have_http_status(:not_found)
  end
end
