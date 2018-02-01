class CreateDataProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :data_products do |t|
      t.integer :status
      t.string :raw_data_path
      t.string :raw_data_format

      t.timestamps
    end
  end
end
