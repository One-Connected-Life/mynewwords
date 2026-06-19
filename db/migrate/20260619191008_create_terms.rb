class CreateTerms < ActiveRecord::Migration[8.1]
  def change
    create_table :terms do |t|
      t.references :deck, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
