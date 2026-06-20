# FSRS scheduling tweaks the learner triggers by hand (#axis-4):
#   unretire — bring a retired word back to drilling (from the /stats shelf)
#   nudge    — adjust a word's ease 1–5 mid-drill (AI-prefilled, user-adjustable)
#
# Both operate on the (current_user, term, from, to) scheduling row. They are
# no-ops in legacy mode only in the sense that no scheduling rows exist then;
# the routes stay live so the JS/UI can call them once FSRS is on.
class SchedulingsController < ApplicationController
  # PATCH /terms/:id/unretire — direction is target→source (the /stats shelf direction).
  def unretire
    term = current_user.terms.find(params[:id])
    scheduling = current_user.schedulings.find_by(
      term_id:       term.id,
      from_language: current_user.target_language,
      to_language:   current_user.source_language
    )
    scheduling&.unretire!
    redirect_to stats_path, notice: "Brought a word back to drilling."
  end

  # PATCH /terms/:id/ease — { ease:, from:, to: }. Creates the row if missing
  # so an ease nudge works even before the word's first FSRS grade.
  def nudge
    term = current_user.terms.find(params[:id])
    scheduling = current_user.schedulings.find_or_initialize_by(
      term_id:       term.id,
      from_language: params[:from].presence || current_user.target_language,
      to_language:   params[:to].presence   || current_user.source_language
    )
    scheduling.nudge_ease!(params[:ease])
    head :no_content
  end
end
