require 'integration_helper'

describe 'Campaigns requests' do
  context 'when unauthenticated' do
    describe 'GET #index' do
      it 'responds with a redirect to the login page' do
        get site_campaigns_path 1

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

    describe 'GET #index' do
      it 'responds with a redirect to the root path' do
        get site_campaigns_path site

        expect(response).to be_a_redirect
      end
    end
  end

  context 'when authenticated' do
    let(:user) { create :user }
    let(:site) { create :site, user: user }
    let(:contact_list) { create :contact_list, site: site }
    let!(:subscription) { create :subscription, :pro_managed, site: site }

    let(:campaign_params) do
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

    describe 'GET #index' do
      it 'responds with success' do
        get site_campaigns_path site

        expect(response).to be_successful
      end
    end

    describe 'GET #show' do
      let(:campaign) { create :campaign, site: site, contact_list: contact_list }

      it 'responds with success' do
        get site_campaign_path site, campaign

        expect(response).to be_successful
      end
    end

    describe 'GET #new' do
      it 'responds with success' do
        get new_site_campaign_path site

        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      it 'creates a new email campaign when params are correct' do
        expect {
          post site_campaigns_path(site), campaign: campaign_params
        }.to change { Campaign.count }.by 1

        expect(response).to be_a_redirect
      end

      it 'does not create a new email campaign when some params are missing' do
        params = Hash[campaign: campaign_params.merge(name: '')]

        expect {
          post site_campaigns_path(site), params
        }.not_to change { Campaign.count }

        expect(response).to be_successful
      end
    end

    describe 'GET #edit' do
      let(:campaign) { create :campaign, site: site, contact_list: contact_list }

      it 'responds with success' do
        get edit_site_campaign_path site, campaign

        expect(response).to be_successful
      end
    end

    describe 'PATCH #update' do
      let(:campaign) { create :campaign, site: site, contact_list: contact_list }

      it 'updates data of an existing email campaign when params are correct' do
        params = Hash[campaign: campaign_params]

        expect {
          patch site_campaign_path(site, campaign), params
        }.to change { campaign.reload.name }.to campaign_params[:name]

        expect(response).to be_a_redirect
      end

      it 'does not update an email campaign when some params are missing' do
        params = Hash[campaign: campaign_params.merge(name: '')]

        expect {
          patch site_campaign_path(site, campaign), params
        }.not_to change { campaign.reload.name }

        expect(response).to be_successful
      end
    end

    describe 'POST #send_out' do
      let(:campaign) { create :campaign, site: site, contact_list: contact_list }

      it 'sends out SNS notification to send out the campaign' do
        expect(SendSnsNotification).to receive_service_call

        post send_out_site_campaign_path(site, campaign)

        expect(response).to be_a_redirect
      end
    end
  end
end
