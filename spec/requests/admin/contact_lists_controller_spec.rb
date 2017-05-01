describe Admin::ContactListsController do
  let(:admin) { create(:admin) }
  let(:site) { create(:site, :with_user) }
  let!(:user) { site.owners.last }
  let!(:contact_list) { create :contact_list, site: site }

  before { stub_current_admin(admin) }

  describe 'GET admin_user_site_contact_lists_path' do
    it 'allows admins to see contact lists of the site' do
      get admin_user_site_contact_lists_path(user_id: user, site_id: site)
      expect(response).to be_success
      expect(response.body).to include contact_list.name
    end
  end
end
