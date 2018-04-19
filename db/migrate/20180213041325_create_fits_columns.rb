class CreateFitsColumns < ActiveRecord::Migration[5.1]
  def change
    create_table :fits_columns do |t|
      t.references :data_product, foreign_key: true
      t.string :identifier
      t.string :name
      t.string :description
      t.string :type_alt
      t.integer :verb_level
      t.string :unit
      t.string :ucds
      t.boolean :required

      t.timestamps
    end
  end
end
