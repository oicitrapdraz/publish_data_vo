class CreateMetadataCoverageWavebands < ActiveRecord::Migration[5.1]
  def change
    create_table :metadata_coverage_wavebands do |t|
      t.string :name

      t.timestamps
    end
  end
end
