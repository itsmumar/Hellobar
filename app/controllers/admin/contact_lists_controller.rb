class Admin::ContactListsController < AdminController
  before_action :load_site

  def index
    @contact_lists = @site.contact_lists.with_deleted
    @subscribers_count = FetchSiteContactListTotals.new(@site, @contact_lists.map(&:id)).call
  end

  def show
    @contact_list = @site.contact_lists.with_deleted.find(params[:id])
    @subscribers = FetchSubscribers.new(@contact_list, pagination_params).call
    @total_subscribers = FetchSiteContactListTotals.new(@site, [@contact_list.id]).call[@contact_list.id]
  end

  private

  def load_site
    @site = Site.find(params[:site_id])
  end

  def pagination_params
    {
      key: params[:key],
      forward: ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:forward]) || false
    }
  end
end
