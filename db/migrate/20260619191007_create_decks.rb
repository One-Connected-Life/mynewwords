class CreateDecks < ActiveRecord::Migration[8.1]
  def change
    create_table :decks do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :decks, :slug, unique: true
  end
end
