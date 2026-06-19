class CreateTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :translations do |t|
      t.references :term, null: false, foreign_key: true
      t.string :language, null: false
      t.string :text, null: false
      t.string :article

      t.timestamps
    end
    add_index :translations, [:term_id, :language], unique: true
  end
end
