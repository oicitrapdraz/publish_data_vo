class CreateDataProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :data_products do |t|
      t.integer :status
      t.string :schema
      t.string :resource_directory
      t.string :filename
      t.string :format

      t.timestamps
    end
  end
end
