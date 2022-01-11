class CreateRandomStrings < ActiveRecord::Migration[7.0]
  def change
    create_table :random_strings do |t|
      t.string :random_string

      t.timestamps
    end
  end
end
