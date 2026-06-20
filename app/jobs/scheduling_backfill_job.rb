# Pre-flag-on FSRS backfill (#axis-4).
#
# Before flipping FSRS_ENABLED globally, run this once so every (user, term,
# direction) the user has ever drilled already has a populated Scheduling card.
# Otherwise the FIRST live FSRS grade replays that term's whole attempt history
# inside the request (AttemptsController#backfill_scheduling!) — slow for users
# with long histories. This job does that replay ahead of time, in the background.
#
# Idempotent: skips rows already marked backfilled. Safe to re-run. Pass a
# user_id to scope to one learner (e.g. after import); omit to backfill everyone.
#
#   bin/rails runner "SchedulingBackfillJob.perform_now"
class SchedulingBackfillJob < ApplicationJob
  queue_as :default

  def perform(user_id = nil)
    scope = user_id ? User.where(id: user_id) : User.all
    scope.find_each { |user| backfill_user(user) }
  end

  private

  def backfill_user(user)
    # Prefill ease for the learner's primary direction first, so the replay seeds
    # FSRS initial difficulty from the right rating. Other directions fall back to
    # whatever ease the row carries (default 3).
    words = user.terms.where(kind: "word").includes(:translations).to_a
    EasePrefillService.new(user).upsert_ease!(words) if words.any?

    scheduler = FsrsScheduler.new
    user.attempts.distinct.pluck(:term_id, :from_language, :to_language).each do |term_id, from, to|
      scheduling = user.schedulings.find_or_initialize_by(
        term_id: term_id, from_language: from, to_language: to
      )
      next if scheduling.backfilled?

      history = user.attempts
                    .where(term_id: term_id, from_language: from, to_language: to)
                    .order(:id)
                    .to_a
      card = scheduler.replay(history, ease: scheduling.ease || 3)
      scheduling.assign_attributes(card.slice(*FsrsScheduler::CARD_KEYS))
      scheduling.backfilled = true
      scheduling.save!
    end
  end
end
