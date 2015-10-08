class ImageUploadsController < ApplicationController
  before_action :load_site, :load_site_element
  respond_to :json

  def create
    image_upload = @site.image_uploads.new(image: params[:file])
    @site_element.update(image_upload: image_upload)

    if image_upload.save && @site_element.update(image_upload_id: image_upload.id)
      render status: 200, json: image_upload
    else
      render status: 500, json: { errors: image_upload.errors.full_messages}
    end
  end

  def destroy
    site_element = SiteElement.find params[:id]

    if site_element.image_upload.nil?
      render status: 404, json: {}
    elsif site_element.image_upload.delete
      render status: 200, json: {}
    else
      render status: 500, json: { errors: image_upload.errors.full_messages}
    end
  end

  private
  def load_site_element
    @site_element = SiteElement.find params[:site_element_id]
  end
end
