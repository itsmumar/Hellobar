class ImageUploadsController < ApplicationController
  before_action :load_site, :load_site_element
  respond_to :json

  def create
    image_upload = @site.image_uploads.new(image: params[:file])
    #@site_element.update(image_upload: image_upload)

    if image_upload.save #&& @site_element.update(image_upload_id: image_upload.id)
      render json: image_upload, status: 200
    else
      render json: { error: image_upload.errors.full_messages.join("; ") }, status: 500
    end
  end

  private
  def load_site_element
    @site_element = SiteElement.find params[:site_element_id]
  end
end
