class HomeController < ApplicationController
  def index
  end

  def example
      @data_product = DataProduct.find(1)

      @types = File.readlines('vocabulary/column_types.txt')

      result = `python fits_column_parser.py #{File.join(@data_product.resource_directory, @data_product.filename)} #{@data_product.hdu_index}`
      
      fits = JSON.parse(result)

      @columns = fits['columns'].insert(0, '')

      @raw_units = fits['units']
      @raw_ucds = fits['ucds']

      @units = fits['units'].uniq.sort  
      @ucds = fits['ucds'].uniq.sort
  end
end
