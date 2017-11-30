class Admin::ContactListsController < AdminController
  before_action :load_site

  def index
    @contact_lists = @site.contact_lists
    @contacts = @contact_lists.each.with_object({}) do |contact_list, memo|
      memo[contact_list.id] = FetchContacts::Latest.new(contact_list, limit: 20).call
    end
  end

  private

  def load_site
    @site = Site.find(params[:site_id])
  end
end
