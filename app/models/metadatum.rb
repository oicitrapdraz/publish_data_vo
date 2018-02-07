class Metadatum < ApplicationRecord
  belongs_to :data_product

  validates :data_product_id, presence: true
  validates :title, presence: true
  validates :description, presence: true
  validates :creation_date, presence: true
  validates :creators, presence: true
  validates :subjects, presence: true
  validates :instrument, presence: true
  validates :facility, presence: true
  validates :type_alt, presence: true
  validates :coverage_profile, presence: true
  validates :coverage_waveband, presence: true
end
