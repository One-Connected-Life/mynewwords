require "rails_helper"

# SchedulingBackfillJob — pre-flag-on FSRS backfill (#axis-4).
# Builds Scheduling cards from attempt history so the first live FSRS grade
# doesn't replay a term's whole history in-request.
RSpec.describe SchedulingBackfillJob, type: :job do
  let(:user) { create(:user, target_language: "nl", source_language: "en") }
  let(:deck) { create(:deck, user: user) }
  let(:term) { create(:term, deck: deck) }

  before do
    create(:translation, term: term, language: "nl", text: "hond")
    create(:translation, term: term, language: "en", text: "dog")
  end

  it "builds a backfilled scheduling row from attempt history" do
    3.times { create(:attempt, user: user, term: term, from_language: "nl", to_language: "en", correct: true) }

    expect {
      described_class.perform_now(user.id)
    }.to change(Scheduling, :count).by(1)

    sched = Scheduling.find_by(user: user, term: term, from_language: "nl", to_language: "en")
    expect(sched.backfilled).to be(true)
    expect(sched.reps).to eq(3)
  end

  it "is idempotent — skips rows already backfilled" do
    create(:attempt, user: user, term: term, from_language: "nl", to_language: "en", correct: true)
    described_class.perform_now(user.id)
    sched = Scheduling.last
    expect(sched.backfilled).to be(true)

    expect {
      described_class.perform_now(user.id)
    }.not_to change { sched.reload.updated_at }
  end

  it "scopes to a single user when given a user_id" do
    other = create(:user, target_language: "nl", source_language: "en")
    create(:attempt, user: other, term: term, from_language: "nl", to_language: "en", correct: true)
    create(:attempt, user: user,  term: term, from_language: "nl", to_language: "en", correct: true)

    described_class.perform_now(user.id)

    expect(Scheduling.where(user: user)).to exist
    expect(Scheduling.where(user: other)).not_to exist
  end
end
