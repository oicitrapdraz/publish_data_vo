require 'json'
require 'nokogiri'
require 'fileutils'

class PublishController < ApplicationController
  before_action :authenticate_admin!, only: [:first_check, :accepted, :generate_rd, :final_check, :imp_q]

  def create_publish_request
    if request.get?
    end

    if request.post?
      begin

        # Create the resource_directory and write raw_data there

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

        data_product = DataProduct.create(status: 0, schema: schema, resource_directory: resource_directory, filename: File.join('data', uploaded_data.original_filename), format: raw_data_format, hdu_index: params[:hdu_index])

        data_product.metadatum = Metadatum.create(metadatum_params)

        redirect_to action: 'metadata', id: data_product.id
      rescue StandardError => error
        redirect_to publish_create_publish_request_path, flash: { alert: 'An error ocurred... Please be sure to fill in all the fields' }

        FileUtils.rm_r(resource_directory) if File.exists?(resource_directory)
      end
    end
  end

  def metadata
    if request.get?
      @data_product = DataProduct.find(params[:id])

      result = `python fits_metadata_parser.py #{File.join(@data_product.resource_directory, @data_product.filename)} #{@data_product.hdu_index}`
      
      metadata = JSON.parse(result)

      @creators = metadata['creator']
      @instrument = metadata['instrument']
      @facility = metadata['facility']

      @types = File.readlines('vocabulary/meta_types.txt').sort!
      @coverage_wavebands = File.readlines('vocabulary/meta_coverage_wavebands.txt').sort!
      @subjects = File.readlines('vocabulary/meta_subjects.txt').sort!
    end

    if request.post?
      begin
        # Update data_product and associated metadata

        @data_product = DataProduct.find(params[:data_product_id])

        subjects = metadatum_params[:subjects].reject { |s| s.empty? }.join(';')

        coverage_wavebands = metadatum_params[:coverage_wavebands].reject { |cw| cw.empty? }.join(';')

        types = metadatum_params[:types].reject { |ta| ta.empty? }.join(';')

        @data_product.metadatum.update_attributes(metadatum_params.except(:coverage_wavebands).except(:subjects).except(:types).merge(coverage_wavebands: coverage_wavebands).merge(subjects: subjects).merge(types: types))

        redirect_to action: 'select_data', id: @data_product.id
      rescue StandardError => error
        puts(error)
        redirect_to publish_metadata_path(id: @data_product_id.id), flash: { alert: 'An error ocurred... Please be sure to fill in all the fields' }
      end
    end
  end

  def select_data
    if request.get?
      @data_product = DataProduct.find(params[:id])

      result = `python fits_column_parser.py #{File.join(@data_product.resource_directory, @data_product.filename)} #{@data_product.hdu_index}`
      
      fits = JSON.parse(result)

      @columns = fits['columns']
    end

    if request.post?
      @data_product = DataProduct.find(params[:data_product_id])

      params[:columns].each_with_index { |val, index|
        @data_product.fits_columns.create(identifier: val)
      }

      redirect_to action: 'parse_match', id: @data_product.id
    end
  end

  def parse_match
    if request.get?
      @data_product = DataProduct.find(params[:id])

      @types = File.readlines('vocabulary/column_types.txt')

      result = `python fits_column_parser.py #{File.join(@data_product.resource_directory, @data_product.filename)} #{@data_product.hdu_index}`
      
      fits = JSON.parse(result)

      @columns = fits['columns'].insert(0, '')

      @raw_comments = fits['comments']
      @raw_formats = fits['formats']
      @raw_units = fits['units']
      @raw_ucds = fits['ucds']

      @units = fits['units'].uniq.sort  
      @ucds = fits['ucds'].uniq.sort
    end

    if request.post?
      params[:fits_column_id].each_with_index { |val, index|

        col = FitsColumn.find(val)
        
        col.update_attributes(name: params[:name][index], description: params[:description][index], type_alt: params[:type_alt][index], verb_level: params[:verb_level][index], unit: params[:unit][index], ucds: params[:ucds][index], required: params[:required][index])
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

      dachs_directory = File.read('dachs_directory')

      if dachs_directory == '/var/gavo/inputs'
        @can_publish = true
      end

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

            data_product.metadatum.types.split(';').map(&:strip).each do |type|
              xml.meta('name' => 'type') { xml.text("#{type}") }
            end

            xml.meta('name' => 'facility') { xml.text("#{data_product.metadatum.facility}") }
            xml.meta('name' => 'instrument') { xml.text("#{data_product.metadatum.instrument}") }

            coverage_wavebands = data_product.metadatum.coverage_wavebands.split(';')

            if coverage_wavebands.length == 1
              xml.meta('name' => 'coverage.waveband') { xml.text("#{coverage_wavebands.first}") }
            else
              xml.meta('name' => 'coverage') do
                data_product.metadatum.coverage_wavebands.split(';').map(&:strip).each do |waveband|
                  xml.meta('name' => 'waveband') { xml.text("#{waveband}") }
                end
              end       
            end

            # Table

            # Verificamos si se encuentra RA y DEC dentro de las columnas, si estan entonces usamos el mixin SCS

            ra_presence = false
            dec_presence = false

            data_product.fits_columns.each do |col|
              ra_presence = true if col.ucds == 'pos.eq.ra;meta.main'
              dec_presence = true if col.ucds == 'pos.eq.dec;meta.main'
            end

            if ra_presence and dec_presence
              table_att = {'id' => 'main', 'onDisk' => 'True', 'adql' => 'True', 'mixin' => '//scs#q3cindex'}
            else
              table_att = {'id' => 'main', 'onDisk' => 'True', 'adql' => 'True'}
            end

            # Asumimos que solamente se agregan columnas de un solo HDU, en caso de que se quieran publicar columnas de diferentes HDUs (que problablemente tienen diferente cantidad de filas) es necesario definir mas de una tabla y hacer mas de un import

            xml.table(table_att) do
              data_product.fits_columns.each do |col|
                column_att = Hash.new

                column_att["name"] = "#{col.name}"
                column_att[:verbLevel] = "#{col.verb_level}"
                column_att[:type] = "#{col.type_alt}"
                column_att[:required] = "#{col.required.to_s.capitalize}"

                if not col.description.blank?
                  column_att[:description] = "#{col.description}"
                end

                if not col.unit.blank?
                  column_att[:unit] = "#{col.unit}"
                end

                if not col.ucds.blank?
                  column_att[:ucd] = "#{col.ucds}"
                end

                xml.column(column_att)
              end
            end

            xml.data('id' => 'import') do
              xml.sources { xml.text("#{data_product.filename}") }

              xml.fitsTableGrammar('hdu' => "#{data_product.hdu_index}")

              xml.make('table' => 'main') do
                xml.rowmaker do
                  data_product.fits_columns.each do |col|
                    xml.map('dest' => "#{col.name}") { xml.text("@#{col.identifier}") }
                  end
                end
              end
            end

            id_prescence = false
            id_col_name = nil

            data_product.fits_columns.each do |col|
              if col.ucds == 'meta.id;meta.main'
                id_prescence = true
                id_col_name = col.name
              end
            end

            if ra_presence and dec_presence and id_prescence
              shortname = data_product.metadatum.title.downcase.split.map(&:first).join

              xml.service('id' => 'cone', 'defaultRenderer' => 'form', 'allowed' => 'scs.xml,form,static') do
                xml.meta('name' => 'title') { xml.text("#{data_product.metadatum.title.split(' ').first.downcase} SCS") }     

                xml.meta('name' => 'shortName') { xml.text("#{shortname}c") }

                xml.scsCore('queriedTable' => 'main') do
                  xml.FEED('source' => '//scs#coreDescs')
                end

                xml.outputTable('verbLevel' => '20')
              end

              xml.service('id' => 'get_data', 'defaultRenderer' => 'form', 'allowed' => 'form,static') do
                xml.meta('name' => 'title') { xml.text("#{data_product.metadatum.title.split(' ').first.downcase} Get data") }
                xml.meta('name' => 'shortName') { xml.text("#{shortname}gd") }

                xml.dbCore('queriedTable' => 'main') do
                  xml.condDesc do
                    xml.inputKey('original' => "#{id_col_name}", 'required' => 'True')
                  end
                end

                xml.outputTable('verbLevel' => '30')
              end
            elsif id_prescence
              xml.service('id' => 'get_data', 'defaultRenderer' => 'form', 'allowed' => 'form,static') do
                xml.meta('name' => 'title') { xml.text("#{data_product.metadatum.title.split(' ').first.downcase} Get data") }

                shortname = data_product.metadatum.title.downcase.split.map(&:first).join

                xml.meta('name' => 'shortName') { xml.text("#{shortname}gd") }

                xml.dbCore('queriedTable' => 'main') do
                  xml.condDesc do
                    xml.inputKey('original' => "#{id_col_name}", 'required' => 'True')
                  end
                end

                xml.outputTable('verbLevel' => '30')
              end
            end
          end
        end

        file.write Nokogiri::XML(builder.to_xml).root.to_xml
        
        file.close

        redirect_to publish_generate_rd_path, flash: { notice: 'Successfully generated the resource descriptor...' }
      rescue StandardError => error
        puts(error)
        redirect_to publish_generate_rd_path, flash: { alert: 'An error ocurred during this proccess...' }
      end
    end
  end

  def imp_q
    data_product = DataProduct.find(params[:id])

    result = `gavo --debug imp #{data_product.metadatum.title.split(' ').first.downcase}/q.rd`

    redirect_to publish_generate_rd_path, flash: { notice: "#{result}" }
  end

  private

    def metadatum_params
      params.permit(:title, :description, :creators, :instrument, :facility, :source, types: [], subjects: [], coverage_wavebands: [])
    end
end
