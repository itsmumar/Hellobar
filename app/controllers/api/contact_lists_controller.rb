class Api::ContactListsController < Api::BaseController
  def index
    render json: @current_site.contact_lists,
      each_serializer: ContactListSerializer
  end
end
