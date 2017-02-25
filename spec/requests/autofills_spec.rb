require 'integration_helper'

describe "Autofills requests" do

  context 'when unauthenticated' do
    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get site_autofills_path 1

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated but without ProManaged subscription' do
    let!(:subscription) { create :subscription, :pro }
    let(:user) { subscription.user }
    let(:site) { subscription.site }
    let!(:site_membership) { create :site_membership, site: site, user: user }

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      it 'responds with a redirect to the root path' do
        get site_autofills_path site

        expect(response).to be_a_redirect
      end
    end
  end

  context 'when authenticated' do
    let!(:subscription) { create :subscription, :pro_managed }
    let(:user) { subscription.user }
    let(:site) { subscription.site }
    let!(:site_membership) { create :site_membership, site: site, user: user }

    let(:autofill_params) do
      {
        name: 'Name',
        listen_selector: 'input.name',
        populate_selector: 'input.name'
      }
    end

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      it 'responds with success' do
        get site_autofills_path site

        expect(response).to be_successful
      end
    end

    describe 'GET :new' do
      it 'responds with success' do
        get new_site_autofill_path site

        expect(response).to be_successful
      end
    end

    describe 'POST :create' do
      it 'creates a new autofill when params are correct' do
        expect {
          post site_autofills_path(site), autofill: autofill_params
        }.to change { Autofill.count }.by 1

        expect(response).to be_a_redirect
      end

      it 'does not create a new autofill when some params are missing' do
        params = Hash[autofill: autofill_params.merge(name: '')]

        expect {
          post site_autofills_path(site), params
        }.not_to change { Autofill.count }

        expect(response).to be_successful
      end
    end

    describe 'GET :edit' do
      let(:autofill) { create :autofill, site: site }

      it 'responds with success' do
        get edit_site_autofill_path site, autofill

        expect(response).to be_successful
      end
    end

    describe 'PATCH :update' do
      let(:autofill) { create :autofill, site: site }

      it 'updates data of an existing autofill when params are correct' do
        params = Hash[autofill: autofill_params]

        expect {
          patch site_autofill_path(site, autofill), params
        }.to change { autofill.reload.name }.to autofill_params[:name]

        expect(response).to be_a_redirect
      end

      it 'does not update an autofill when some params are missing' do
        params = Hash[autofill: autofill_params.merge(name: '')]

        expect {
          patch site_autofill_path(site, autofill), params
        }.not_to change { autofill.reload.name }.to autofill_params[:name]

        expect(response).to be_successful
      end
    end

    describe 'DELETE :destroy' do
      let!(:autofill) { create :autofill, site: site }

      it 'destroys an existing autofill' do
        expect {
          delete site_autofill_path(site, autofill)
        }.to change { Autofill.count }.by -1

        expect(response).to be_a_redirect
      end
    end
  end

end
