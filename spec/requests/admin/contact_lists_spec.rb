describe 'Admin::ContactLists requests' do
  let(:admin) { create(:admin) }
  let(:site) { create(:site, :with_user) }
  let!(:user) { site.owners.last }
  let!(:contact_list) { create :contact_list, site: site }
  let(:email) { 'user@example.com' }
  let(:status) { 'synced' }

  before do
    stub_current_admin(admin)

    allow_any_instance_of(FetchContacts::Latest).to receive(:call).and_return([
      { email: email, status: status, subscribed_at: Time.current }
    ])
  end

  describe 'GET admin_user_site_contact_lists_path' do
    it 'allows admins to see contact lists of the site' do
      get admin_user_site_contact_lists_path(user_id: user, site_id: site)

      expect(response).to be_success
      expect(response.body).to include contact_list.name
      expect(response.body).to include email
      expect(response.body).to include status
    end
  end
end
