require 'nokogiri'
require 'fileutils'

class PublishController < ApplicationController
  def metadata
    if request.get?
      @types = MetadataType.all
      @coverage_wavebands = MetadataCoverageWaveband.all
    end

    if request.post?
      begin
        # Create resource_directory and write raw_data there

        dachs_directory = File.read('dachs_directory')

        uploaded_data = params[:data]

        schema = metadatum_params[:title].split(' ').first.downcase

        resource_directory = File.join(dachs_directory, schema)

        Dir.mkdir(resource_directory) unless File.exists?(resource_directory)

        raw_data_path = File.join(dachs_directory, resource_directory, uploaded_data.original_filename)

        File.open(raw_data_path, 'wb') do |file|
          file.write(uploaded_data.read)
        end

        # Create data_product and associated metadata

        raw_data_format = uploaded_data.original_filename.split('.').last

        data_product = DataProduct.create(status: 0, schema: schema, resource_directory: resource_directory, filename: uploaded_data.original_filename, format: raw_data_format)

        coverage_waveband = metadatum_params[:coverage_waveband].reject { |cw| cw.empty? }.join(';')

        data_product.metadatum = Metadatum.create(metadatum_params.except(:coverage_waveband).merge(coverage_waveband: coverage_waveband))

        redirect_to action: 'parse_match'
      rescue StandardError => error
        redirect_to publish_metadata_path, flash: { error: 'An error ocurred... Please be sure to fill in all the fields' }

        FileUtils.rm_r(resource_directory) if File.exists?(resource_directory)
      end
    end
  end

  def parse_match
  end

  def first_check
    @data_products = DataProduct.where(status: 0)
  end

  def accepted
    @data_products = DataProduct.where(status: 1)
  end

  def generate_rd
    if request.get?
      # Cambiar status a 2 o 3
      @data_products = DataProduct.where(status: 0)
    end

    if request.post?
      begin
        data_product = DataProduct.find(params[:id])

        file = File.new(File.join(data_product.resource_directory, 'q.rd'), 'wb')

        # Writing resource descriptor

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.resource('schema' => "#{data_product.metadatum.title.split(' ').first.downcase}") do

            # Metadatos
            
            xml.meta('name' => 'title') { xml.text("#{data_product.metadatum.title}") }
            xml.meta('name' => 'description') { xml.text("#{data_product.metadatum.description}") }
            xml.meta('name' => 'creationDate') { xml.text("#{data_product.metadatum.creation_date.strftime('%FT%T')}") }

            data_product.metadatum.creators.split(';').map(&:strip).each do |creator|
              xml.meta('name' => 'creator') do
                xml.meta('name' => 'name') { xml.text("#{creator}") }
              end
            end

            data_product.metadatum.subjects.split(';').map(&:strip).each do |subject|
              xml.meta('name' => 'subject') { xml.text("#{subject}") }
            end

            xml.meta('name' => 'type') { xml.text("#{data_product.metadatum.type_alt}") }

            xml.meta('name' => 'coverage') do
              xml.meta('name' => 'profile') { xml.text("#{data_product.metadatum.coverage_profile}") }
              xml.meta('name' => 'waveband') { xml.text("#{data_product.metadatum.coverage_waveband}") }
            end         
          end
        end

        file.write Nokogiri::XML(builder.to_xml).root.to_xml
        
        file.close

        redirect_to root_path
      rescue StandardError => error
        redirect_to publish_generate_rd_path, flash: { error: 'An error ocurred during this proccess...' }
      end
    end
  end

  def final_check
  end

  private

    def metadatum_params
      params.permit(:title, :description, :creation_date, :creators, :subjects, :instrument, :facility, :type_alt, :coverage_profile, coverage_waveband: [])
    end
end
