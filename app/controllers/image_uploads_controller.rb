class ImageUploadsController < ApplicationController
  before_action :load_site, :load_site_element
  respond_to :json

  def create
    image_upload = ImageUpload.new(image: params[:file], site_element: @site_element)

    if image_upload.save
      render json: image_upload, status: 200
    else
      render json: { error: image_upload.errors.full_messages.join("; ") }, status: 500
    end
  end

  private
  def load_site_element
    @site_element = @site.site_elements.find params[:site_element_id]
  end
end