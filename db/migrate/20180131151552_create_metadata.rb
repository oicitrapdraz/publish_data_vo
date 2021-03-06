class CreateMetadata < ActiveRecord::Migration[5.1]
  def change
    create_table :metadata do |t|
      t.references :data_product, foreign_key: true
      t.string :title
      t.text :description
      t.string :creators
      t.string :subjects
      t.string :source
      t.string :instrument
      t.string :facility
      t.string :types
      t.string :coverage_wavebands

      t.timestamps
    end
  end
end
