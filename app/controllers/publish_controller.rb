require 'json'
require 'nokogiri'
require 'fileutils'

class PublishController < ApplicationController
  before_action :authenticate_admin!, only: [:first_check, :accepted, :generate_rd, :final_check, :imp_q]

  def metadata
    if request.get?
      @types = File.readlines('vocabulary/meta_types.txt').sort!
      @coverage_wavebands = File.readlines('vocabulary/meta_coverage_wavebands.txt').sort!
      @subjects = File.readlines('vocabulary/meta_subjects.txt').sort!
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

        subjects = metadatum_params[:subjects].reject { |s| s.empty? }.join(';')

        coverage_waveband = metadatum_params[:coverage_waveband].reject { |cw| cw.empty? }.join(';')

        data_product.metadatum = Metadatum.create(metadatum_params.except(:coverage_waveband).except(:subjects).merge(coverage_waveband: coverage_waveband).merge(subjects: subjects))

        redirect_to action: 'parse_match', id: data_product.id
      rescue StandardError => error
        puts(error)
        redirect_to publish_metadata_path, flash: { alert: 'An error ocurred... Please be sure to fill in all the fields' }

        FileUtils.rm_r(resource_directory) if File.exists?(resource_directory)
      end
    end
  end

  def parse_match
    if request.get?
      @data_product = DataProduct.find(params[:id])

      @types = File.readlines('vocabulary/column_types.txt')

      result = `python fits_parser_3.py #{File.join(@data_product.resource_directory, @data_product.filename)} #{@data_product.hdu_index}`
      fits = JSON.parse(result)

      @columns = fits['columns'].insert(0, '')

      @raw_units = fits['units']
      @raw_ucds = fits['ucds']

      @units = fits['units'].uniq.sort
      @ucds = fits['ucds'].uniq.sort
    end

    if request.post?
      data_product = DataProduct.find(params[:id])

      params[:identifier].each_with_index { |val, index|
        data_product.fits_columns.create(identifier: params[:identifier][index], name: params[:name][index], description: params[:description][index], type_alt: params[:type_alt][index], verb_level: params[:verb_level][index], unit: params[:unit][index], ucds: params[:ucds][index], required: params[:required][index])
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

            coverage_wavebands = data_product.metadatum.coverage_waveband.split(';')

            if coverage_wavebands.length == 1
              xml.meta('name' => 'coverage.waveband') { xml.text("#{coverage_wavebands.first}") }
            else
              xml.meta('name' => 'coverage') do
                data_product.metadatum.coverage_waveband.split(';').map(&:strip).each do |waveband|
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
                if col.ucds.blank? and col.unit.blank? 
                  column_att = {'name' => "#{col.name}", 'description' => "#{col.description}", 'type' => "#{col.type_alt}", 'verbLevel' => "#{col.verb_level}", 'required' => "#{col.required.to_s.capitalize}"}
                elsif col.ucds.blank?
                  column_att = {'name' => "#{col.name}", 'description' => "#{col.description}", 'type' => "#{col.type_alt}", 'unit' => "#{col.unit}", 'verbLevel' => "#{col.verb_level}", 'required' => "#{col.required.to_s.capitalize}"}
                elsif col.unit.blank?
                  column_att = {'name' => "#{col.name}", 'description' => "#{col.description}", 'type' => "#{col.type_alt}", 'ucd' => "#{col.ucds}", 'verbLevel' => "#{col.verb_level}", 'required' => "#{col.required.to_s.capitalize}"}
                else
                  column_att = {'name' => "#{col.name}", 'description' => "#{col.description}", 'type' => "#{col.type_alt}", 'ucd' => "#{col.ucds}", 'unit' => "#{col.unit}", 'verbLevel' => "#{col.verb_level}", 'required' => "#{col.required.to_s.capitalize}"}
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

            data_product.fits_columns.each do |col|
              id_prescence = true if col.ucds == 'meta.id;meta.main'
            end

            if ra_presence and dec_presence and id_prescence
              xml.service('id' => 'cone', 'defaultRenderer' => 'form', 'allowed' => 'scs.xml,form,static') do
                xml.meta('name' => 'shortname') { xml.text("@#{data_product.metadatum.title.split(' ').first.downcase} cone") }

                xml.scsCore('queriedTable' => 'main') do
                  xml.FEED('source' => '//scs#coreDescs')
                end

                xml.publish('render' => 'scs.xml', 'sets' => 'ivo_managed')

                xml.outputTable('verbLevel' => '20')
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
      params.permit(:title, :description, :creators, :instrument, :facility, :type_alt, :source, subjects: [], coverage_waveband: [])
    end
end
