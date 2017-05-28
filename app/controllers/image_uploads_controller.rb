class ImageUploadsController < ApplicationController
  before_action :load_site
  respond_to :json

  def create
    image_upload = ImageUpload.new(image: params[:file], site: @site)

    if image_upload.save
      render json: image_upload, status: 200
    else
      render json: { error: image_upload.errors.full_messages.join('; ') }, status: 500 # FIXME: should be 422
    end
  end
end
