class AddFlowModeToUsers < ActiveRecord::Migration[8.1]
  def change
    # Flow mode: hands-free listen — hear the prompt, a gap to guess, hear the
    # answer, a gap, then the next card. Off by default; gaps are user-tunable
    # (the 3s default is too short to start guessing — issue: flow mode).
    add_column :users, :flow_mode, :boolean, default: false, null: false
    add_column :users, :flow_gap_prompt, :integer, default: 3, null: false
    add_column :users, :flow_gap_next, :integer, default: 6, null: false
  end
end
