class Api::ContactListsController < Api::ApplicationController
  def create
    @contact_list = site.contact_lists.build(contact_list_params)
    @contact_list.save!

    render json: @contact_list
  end

  private

  def site
    @site ||= current_user.sites.find(params[:site_id])
  end

  def contact_list_params
    params.require(:contact_list).permit(:name)
  end
end
