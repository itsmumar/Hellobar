describe Admin::SitesController do
  let!(:admin) { create(:admin) }
  let(:site) { create(:site, :with_user) }
  let!(:user) { site.owners.first }
  before(:each) { stub_current_admin(admin) }

  context 'PUT update' do
    it 'changes the subscription with the correct payment method and detail' do
      put :update, id: site.id, user_id: site.owners.first.id, subscription: { plan: 'ProComped', schedule: 'monthly' }
      expect(site.reload.current_subscription.is_a?(Subscription::ProComped)).to be_truthy
    end
  end

  context 'PUT update site invoice_information' do
    it 'with the correct data' do
      put :update, id: site.id, user_id: site.owners.first.id, site: { invoice_information: '12345 Main St' }
      expect(site.reload.invoice_information).to eq '12345 Main St'
    end
  end

  describe 'POST #regenerate' do
    context 'when the site exists' do
      before do
        allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)

        allow(User).to receive(:find).and_return(user)
        allow(Site).to receive(:where).and_return([site])

        allow(site).to receive(:generate_script)
      end

      it 'generates the script for the site' do
        post_regenerate

        expect(site).to have_received(:generate_script)
      end

      it 'returns 200' do
        post_regenerate

        expect(response).to be_success
      end

      it 'returns success message' do
        post_regenerate

        expect_json_response_to_include(message: 'Site regenerated')
      end

      context 'when regenerating script fails' do
        before do
          allow(site).to receive(:generate_script).and_raise(RuntimeError)
        end

        it 'returns 500' do
          post_regenerate

          expect(response.status).to eq(500)
        end

        it 'returns error message' do
          post_regenerate

          expect_json_response_to_include(message: "Site's script failed to generate")
        end
      end
    end

    context "when the site doesn't exist" do
      let(:user) { create :user }

      it 'returns a 404' do
        post_regenerate(-1)

        expect(response.status).to eq(404)
      end

      it 'returns error message' do
        post_regenerate(-1)

        expect_json_response_to_include(message: 'Site was not found')
      end
    end

    def post_regenerate(site_id = site.id)
      post :regenerate, user_id: user.id, id: site_id
    end
  end
end
