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
		@types = File.readlines('vocabulary/column_types.txt')

		result = `python fits_parser.py #{File.join(@data_product.resource_directory, @data_product.filename)} #{@data_product.hdu_index}`

		fits = JSON.parse(result)

		@columns = fits['columns'].insert(0, '')

		@raw_units = fits['units']
		@raw_ucds = fits['ucds']

		@units = fits['units'].uniq.sort  
		@ucds = fits['ucds'].uniq.sort
	end

	def update_metadata
		data_product = DataProduct.find(params[:data_product_id])

		if metadatum_params[:title] != data_product.metadatum.title
			begin
				dachs_directory = File.read('dachs_directory')

				schema = metadatum_params[:title].split(' ').first.downcase

				resource_directory = File.join(dachs_directory, schema)

				File.rename(data_product.resource_directory, resource_directory)

				data_product.update_attributes(schema: schema, resource_directory: resource_directory)

				subjects = metadatum_params[:subjects].reject { |s| s.empty? }.join(';')

				coverage_waveband = metadatum_params[:coverage_waveband].reject { |cw| cw.empty? }.join(';')

				data_product.update_attribute('hdu_index', params[:hdu_index])

				data_product.metadatum.update_attributes(metadatum_params.except(:coverage_waveband).except(:subjects).merge(coverage_waveband: coverage_waveband).merge(subjects: subjects))
		
				redirect_to data_product_show_path(id: data_product.id), notice: 'Se actualizaron los datos'
      rescue StandardError => error
        redirect_to publish_metadata_path, flash: { alert: 'An error ocurred... Please be sure to fill in all the fields' }

        FileUtils.rm_r(resource_directory) if File.exists?(resource_directory)
      end
		else
			subjects = metadatum_params[:subjects].reject { |s| s.empty? }.join(';')

			coverage_waveband = metadatum_params[:coverage_waveband].reject { |cw| cw.empty? }.join(';')

			data_product.update_attribute('hdu_index', params[:hdu_index])

			data_product.metadatum.update_attributes(metadatum_params.except(:coverage_waveband).except(:subjects).merge(coverage_waveband: coverage_waveband).merge(subjects: subjects))
	
			redirect_to data_product_show_path(id: data_product.id), notice: 'Se actualizaron los datos'
		end
	end

	def update_columns
		params[:fits_column_id].each_with_index { |val, index|

			col = FitsColumn.find(val)
			
			col.update_attributes(identifier: params[:identifier][index], name: params[:name][index], description: params[:description][index], type_alt: params[:type_alt][index], verb_level: params[:verb_level][index], unit: params[:unit][index], ucds: params[:ucds][index], required: params[:required][index])
		}

		redirect_to data_product_show_path(id: params[:id]), notice: 'Se actualizaron los datos'
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
