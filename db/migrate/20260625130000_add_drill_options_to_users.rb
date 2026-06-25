class AddDrillOptionsToUsers < ActiveRecord::Migration[8.1]
  def change
    # Drill options that used to live in the session (skip_easy, hide_mastered)
    # or browser localStorage (autoplay flags). Persist them per-user so the
    # Settings page (onboarding#show) owns the whole cluster. (Finding A)
    add_column :users, :skip_easy, :boolean, default: false, null: false
    add_column :users, :hide_mastered, :boolean, default: true, null: false
    add_column :users, :autoplay_prompt, :boolean, default: false, null: false
    add_column :users, :autoplay_wrong, :boolean, default: false, null: false
  end
end
