class CreateRandomStrings < ActiveRecord::Migration[5.0]
  def change
    create_table :random_strings do |t|
      t.string :random_string

      t.timestamps null: false
    end
  end
end
