class DataProduct < ApplicationRecord
	has_one :metadatum, dependent: :delete
	has_many :fits_columns, dependent: :delete_all

	validates :status, presence: true
	validates :schema, presence: true
	validates :resource_directory, presence: true
	validates :filename, presence: true
	validates :format, presence: true
end
