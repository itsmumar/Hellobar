describe 'Admin::ContactLists requests' do
  let(:admin) { create(:admin) }
  let(:site) { create(:site, :with_user, :free_subscription) }
  let!(:user) { site.owners.last }
  let!(:contact_list) { create :contact_list, site: site }
  let(:email) { 'user@example.com' }
  let(:status) { 'synced' }
  let(:contacts) { [Contact.new(email: email, status: status, subscribed_at: Time.current)] }

  before do
    stub_current_admin(admin)

    allow(FetchSubscribers).to receive_message_chain(:new, :call).and_return(items: contacts)

    allow(FetchSiteContactListTotals).to receive_message_chain(:new, :call).and_return(Hash.new { 0 })
  end

  describe 'GET admin_user_site_contact_lists_path' do
    it 'allows admins to see contact lists of the site' do
      get admin_site_contact_lists_path(site_id: site)

      expect(response).to be_success
      expect(response.body).to include contact_list.name
    end

    it 'allows admins to see contact lists subscribers' do
      get admin_contact_list_path(contact_list)

      expect(response).to be_success
      expect(response.body).to include email
      expect(response.body).to include status
    end
  end
end
