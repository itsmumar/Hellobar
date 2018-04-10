class Admin::ContactListsController < AdminController
  before_action :load_site

  def index
    @contact_lists = @site.contact_lists.with_deleted
    @subscribers_count = FetchSiteContactListTotals.new(@site, @contact_lists.map(&:id)).call
    @contacts = @contact_lists.each.with_object({}) do |contact_list, memo|
      memo[contact_list.id] = FetchContacts.new(contact_list, page_size: 20).call[:items]
    end
  end

  private

  def load_site
    @site = Site.find(params[:site_id])
  end
end
