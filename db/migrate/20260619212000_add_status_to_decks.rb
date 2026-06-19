class AddStatusToDecks < ActiveRecord::Migration[8.1]
  def change
    # ready (seeded/done) | pending (AI generating) | failed
    add_column :decks, :status, :string, default: "ready", null: false
  end
end
