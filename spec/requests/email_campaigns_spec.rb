require 'integration_helper'

describe 'Email Campaigns requests' do
  context 'when unauthenticated' do
    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get site_email_campaigns_path 1

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated but without ProManaged subscription' do
    let(:user) { create :user }
    let(:site) { create :site, user: user }
    let!(:subscription) { create :subscription, :pro, site: site }

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      it 'responds with a redirect to the root path' do
        get site_email_campaigns_path site

        expect(response).to be_a_redirect
      end
    end
  end

  context 'when authenticated' do
    let(:user) { create :user }
    let(:site) { create :site, user: user }
    let(:contact_list) { create :contact_list, site: site }
    let!(:subscription) { create :subscription, :pro_managed, site: site }

    let(:email_campaign_params) do
      {
        site_id: site.id,
        contact_list_id: contact_list.id,
        name: 'Name',
        from_name: 'Hello Bar',
        from_email: 'me@example.com',
        subject: 'Test',
        body: 'Test'
      }
    end

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      it 'responds with success' do
        get site_email_campaigns_path site

        expect(response).to be_successful
      end
    end
  end
end
