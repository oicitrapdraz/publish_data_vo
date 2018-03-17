require 'json'
require 'nokogiri'
require 'fileutils'

class PublishController < ApplicationController
  def metadata
    if request.get?
      @types = File.readlines('vocabulary/meta_types.txt')
      @coverage_wavebands = File.readlines('vocabulary/meta_coverage_wavebands.txt')
      @subjects = File.readlines('vocabulary/meta_subjects.txt')
    end

    if request.post?
      begin

        # Create resource_directory and write raw_data there

        dachs_directory = File.read('dachs_directory')

        uploaded_data = params[:data]

        schema = metadatum_params[:title].split(' ').first.downcase

        resource_directory = File.join(dachs_directory, schema)

        Dir.mkdir(resource_directory) unless File.exists?(resource_directory)

        Dir.mkdir(File.join(resource_directory, 'data')) unless File.exists?(File.join(resource_directory, 'data'))

        raw_data_path = File.join(resource_directory, 'data', uploaded_data.original_filename)

        File.open(raw_data_path, 'wb') do |file|
          file.write(uploaded_data.read)
        end

        # Create data_product and associated metadata

        raw_data_format = uploaded_data.original_filename.split('.').last

        data_product = DataProduct.create(status: 0, schema: schema, resource_directory: resource_directory, filename: File.join('data', uploaded_data.original_filename), format: raw_data_format)

        subjects = metadatum_params[:subjects].reject { |s| cw.empty? }.join(';')

        coverage_waveband = metadatum_params[:coverage_waveband].reject { |cw| cw.empty? }.join(';')

        data_product.metadatum = Metadatum.create(metadatum_params.except(:coverage_waveband).except(:subjects).merge(coverage_waveband: coverage_waveband).merge(subjects: subjects))

        redirect_to action: 'parse_match', id: data_product.id
      rescue StandardError => error
        puts(error)
        redirect_to publish_metadata_path, flash: { error: 'An error ocurred... Please be sure to fill in all the fields' }

        FileUtils.rm_r(resource_directory) if File.exists?(resource_directory)
      end
    end
  end

  def parse_match
    if request.get?
      @data_product = DataProduct.find(params[:id])

      # Leyendo el contenido del archivo FITS

      result = `python fits_parser.py #{File.join(@data_product.resource_directory, @data_product.filename)}`

      fits = JSON.parse(result)

      print(fits['hdu'].first['content'])

      @hdu_indexes = 0..(fits['hdu'].length - 1)

      @columns = fits['hdu'].first['content']
    end

    if request.post?
      data_product = DataProduct.find(params[:id])

      params[:hdu_index].each_with_index { |val, index|
        data_product.fits_columns.create(hdu_index: params[:hdu_index][index], identifier: params[:identifier][index], name: params[:name][index], description: params[:description][index], type_alt: params[:type_alt][index], verb_level: params[:verb_level][index], unit: params[:unit][index], ucds: 'ucds', required: params[:required][index])
      }

      redirect_to action: 'end'
    end
  end

  def end
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

      @data_products = DataProduct.where(status: 1)
    end

    if request.post?
      begin
        data_product = DataProduct.find(params[:id])

        file = File.new(File.join(data_product.resource_directory, 'q.rd'), 'wb')

        # Escribiendo el resource descriptor

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.resource('schema' => "#{data_product.metadatum.title.split(' ').first.downcase}") do

            # Meta
            
            xml.meta('name' => 'title') { xml.text("#{data_product.metadatum.title}") }
            xml.meta('name' => 'description') { xml.text("#{data_product.metadatum.description}") }
            xml.meta('name' => 'creationDate') { xml.text("#{data_product.metadatum.created_at.strftime('%FT%T')}") }

            xml.meta('name' => 'creator') do
              xml.meta('name' => 'name') { xml.text("#{data_product.metadatum.creators}") }
            end

            data_product.metadatum.subjects.split(';').map(&:strip).each do |subject|
              xml.meta('name' => 'subject') { xml.text("#{subject}") }
            end

            xml.meta('name' => 'type') { xml.text("#{data_product.metadatum.type_alt}") }

            xml.meta('name' => 'facility') { xml.text("#{data_product.metadatum.facility}") }
            xml.meta('name' => 'instrument') { xml.text("#{data_product.metadatum.instrument}") }

            xml.meta('name' => 'coverage') do
              xml.meta('name' => 'profile') { xml.text("#{data_product.metadatum.coverage_profile}") }
              data_product.metadatum.coverage_waveband.split(';').map(&:strip).each do |waveband|
                xml.meta('name' => 'waveband') { xml.text("#{waveband}") }
              end
            end

            # Table

            xml.table('id' => 'main', 'onDisk' => 'True', 'adql' => 'True') do
              data_product.fits_columns.each do |col|
                xml.column('name' => "#{col.name}", 'description' => "#{col.description}", 'type' => "#{col.type_alt}", 'ucd' => "#{col.ucds}", 'unit' => "#{col.unit}", 'verbLevel' => "#{col.verb_level}", 'required' => "#{col.required.to_s.capitalize}")
              end
            end

            xml.data('id' => 'import') do
              xml.make('table' => 'main')

              xml.sources('name' => 'name') do
                xml.pattern { xml.text("#{data_product.metadatum.coverage_waveband}") }
              end
            end

            xml.dbCore

            xml.service
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
      params.permit(:title, :description, :creators, :subjects, :instrument, :facility, :type_alt, :coverage_profile, coverage_waveband: [])
    end
end
