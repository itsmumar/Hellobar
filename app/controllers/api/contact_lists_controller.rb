class Api::ContactListsController < Api::ApplicationController
  def index
    render json: site.contact_lists, each_serializer: ContactListSerializer
  end

  private

  def site
    @site ||= Site.find(params[:site_id])
  end
end
