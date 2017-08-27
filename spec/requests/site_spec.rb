describe 'Site requests' do
  let(:site) { create :site }

  context 'when unauthenticated' do
    describe 'GET :show' do
      it 'responds with a redirect to the login page' do
        get site_path site

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    let(:user) { create :user }
    let!(:site) { create :site, user: user }

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'DELETE :destroy' do
      before do
        expect(GenerateAndStoreStaticScript)
          .to receive_service_call
          .with(site, script_content: '')
      end

      it 'destroys an existing site' do
        expect {
          delete site_path(site)
        }.to change { Site.count }.by(-1)
        expect(response).to be_a_redirect
      end

      it 'voids all pending bills' do
        bill = create :bill, :pending, site: site
        expect { delete site_path(site) }.to change { site.bills.pending.count }.to 0
        expect(bill.reload).to be_voided
      end
    end
  end
end
