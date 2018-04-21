class DataProductController < ApplicationController
	before_action :set_data_product, only: [:accept, :revoke, :show, :update, :edit_metadata, :edit_columns]
	before_action :authenticate_admin!, except: [:show]

	def accept
		@data_product.update_attribute('status', 1)

		redirect_to publish_first_check_path
	end

	def revoke
		@data_product.update_attribute('status', 0)

		redirect_to publish_accepted_path
	end

	def edit_metadata
		@types = File.readlines('vocabulary/meta_types.txt').sort!
		@coverage_wavebands = File.readlines('vocabulary/meta_coverage_wavebands.txt').sort!
		@subjects = File.readlines('vocabulary/meta_subjects.txt').sort!
	end

	def edit_columns
	end

	def update_metadata
		data_product = DataProduct.find(params[:data_product_id])

		if metadatum_params[:title] != data_product.metadatum.title
		# paja, crear directorio, mover archivo, eliminar anterior, cambiar registro, etc 
		else
			subjects = metadatum_params[:subjects].reject { |s| s.empty? }.join(';')

			coverage_waveband = metadatum_params[:coverage_waveband].reject { |cw| cw.empty? }.join(';')

			data_product.update_attribute('hdu_index', params[:hdu_index])

			data_product.metadatum.update_attributes(metadatum_params.except(:coverage_waveband).except(:subjects).merge(coverage_waveband: coverage_waveband).merge(subjects: subjects))
	
			redirect_to data_product_show_path(id: data_product.id), notice: 'Se actualizaron los datos'
		end
	end

	def update_columns
	end

  def show
  end

  private

	  def set_data_product
	  	@data_product = DataProduct.find(params[:id])
	  end

    def metadatum_params
      params.permit(:title, :description, :creators, :instrument, :facility, :type_alt, :source, subjects: [], coverage_waveband: [])
    end
end
