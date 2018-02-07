class DataProductController < ApplicationController
	def accept
		data_product = DataProduct.find(params[:id])

		data_product.update_attribute('status', 1)

		redirect_to publish_first_check_path
	end

	def revoke
		data_product = DataProduct.find(params[:id])

		data_product.update_attribute('status', 0)

		redirect_to publish_accepted_path
	end

  def show
    @data_product = DataProduct.find(params[:id])
  end
end
