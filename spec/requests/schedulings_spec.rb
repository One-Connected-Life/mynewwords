require "rails_helper"

# SchedulingsController — the learner's hand-tweaks on FSRS state (#axis-4):
# un-retire a word from the /stats shelf, and nudge its ease 1–5 mid-drill.
RSpec.describe "Schedulings (FSRS hand-tweaks)", type: :request do
  let(:user) { create(:user, target_language: "nl", source_language: "en") }
  let(:deck) { create(:deck, user: user) }
  let(:term) { create(:term, deck: deck) }

  before do
    create(:translation, term: term, language: "nl", text: "hond")
    create(:translation, term: term, language: "en", text: "dog")
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "PATCH /terms/:id/unretire" do
    it "brings a retired word back into rotation and off the retired shelf" do
      sched = create(:scheduling, user: user, term: term, from_language: "nl", to_language: "en",
                     stability: 365.0, reps: 5, state: 2, due: 1.year.from_now)
      expect(sched.retired?).to be(true)

      patch unretire_term_path(term)
      expect(response).to redirect_to(stats_path)

      sched.reload
      expect(sched.retired?).to be(false)
      expect(sched.stability).to be < Mastery::RETIRE_STABILITY_DAYS
      expect(sched.due).to be <= Time.current
    end

    it "clears the archived flag so a 'done forever' word can be revived" do
      sched = create(:scheduling, user: user, term: term, from_language: "nl", to_language: "en",
                     stability: 365.0, reps: 5, archived: true)
      patch unretire_term_path(term)
      expect(sched.reload.archived).to be(false)
    end

    it "does not touch another user's scheduling" do
      other = create(:user, target_language: "nl", source_language: "en")
      create(:scheduling, user: other, term: term, from_language: "nl", to_language: "en",
             stability: 365.0, reps: 5)
      patch unretire_term_path(term)
      # current_user has no row for this term → no-op, still redirects.
      expect(response).to redirect_to(stats_path)
    end
  end

  describe "PATCH /terms/:id/ease" do
    it "creates a scheduling row with the nudged ease when none exists" do
      expect {
        patch ease_term_path(term), params: { ease: 5, from: "nl", to: "en" }, as: :json
      }.to change(Scheduling, :count).by(1)
      expect(response).to have_http_status(:no_content)
      expect(Scheduling.last.ease).to eq(5)
    end

    it "updates ease on an existing row and clamps out-of-range values" do
      create(:scheduling, user: user, term: term, from_language: "nl", to_language: "en", ease: 3)
      patch ease_term_path(term), params: { ease: 9, from: "nl", to: "en" }, as: :json
      expect(Scheduling.last.ease).to eq(5) # clamped into 1..5
    end
  end
end
