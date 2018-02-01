class PublishController < ApplicationController
  def metadata
    if request.get?
      @types = MetadataType.all
      @coverage_wavebands = MetadataCoverageWaveband.all
    end

    if request.post?
      directory = '/home/patricio/Desktop/var/gavo/inputs'

      uploaded_data = params[:data]

      raw_data_path = File.join(directory, uploaded_data.original_filename)

      File.open(raw_data_path, 'wb') do |file|
        file.write(uploaded_data.read)
      end

      raw_data_format = uploaded_data.original_filename.split('.').last

      data_product = DataProduct.new(status: 0, raw_data_path: raw_data_path, raw_data_format: raw_data_format)

      if data_product.save
        metadatum = Metadatum.create(metadatum_params.except(:coverage_waveband))

        data_product.Metadatum = metadatum
        
        redirect_to action: 'parse_match'
      end
    end
  end

  def parse_match
  end

  def first_check
  end

  def rd
  end

  def final_check
  end

  private

    def metadatum_params
      params.permit(:title, :description, :creation_date, :creators, :subjects, :instrument, :facility, :type, :coverage_profile, :coverage_waveband)
    end
end
