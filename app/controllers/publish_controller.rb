class PublishController < ApplicationController
  def metadata
    if request.get?
      @types = MetadataType.all
      @coverage_wavebands = MetadataCoverageWaveband.all
    end

    if request.post?
      if true #@product.save
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
end
