require 'spec_helper'

describe Admin::SitesController do
  fixtures :all

  before(:each) do
    @admin = admins(:joey)
    stub_current_admin(@admin)
  end

  let(:site) { sites(:zombo) }

  context 'PUT update' do
    it 'changes the subscription with the correct payment method and detail' do
      put :update, id: site.id, user_id: site.owners.first.id, subscription: { plan: 'ProComped', schedule: 'monthly' }
      site.reload.current_subscription.is_a?(Subscription::ProComped).should be_true
    end
  end

  describe "POST #regenerate" do
    before do
      stub_current_admin(@admin)
    end

    context "when the site exists" do
      let(:user) { site.owners.first }

      before do
        Hello::DataAPI.stub(:lifetime_totals => nil)

        allow(User).to receive(:find).and_return(user)
        allow(Site).to receive(:where).and_return([site])

        allow(site).to receive(:generate_script)
      end

      it "generates the script for the site" do
        post_regenerate

        expect(site).to have_received(:generate_script)
      end

      it "returns 200" do
        post_regenerate

        expect(response).to be_success
      end

      it "returns success message" do
        post_regenerate

        expect_json_response_to_include({
          message: "Site script started generating"
        })
      end

      context "when regenerating script fails" do
        before do
          allow(site).to receive(:generate_script).and_raise(RuntimeError)
        end

        it "returns 500" do
          post_regenerate

          expect(response.status).to eq(500)
        end

        it "returns error message" do
          post_regenerate

          expect_json_response_to_include({
            message: "Site's script failed to generate"
          })
        end

      end
    end

    context "when the site doesn't exist" do
      let(:user) { users(:joey) }

      it "returns a 404" do
        post_regenerate(-1)

        expect(response.status).to eq(404)
      end

      it "returns error message" do
        post_regenerate(-1)

        expect_json_response_to_include({
          message: "Site was not found"
        })
      end
    end

    def post_regenerate(site_id = site.id)
      post :regenerate, { user_id: user.id, id: site_id }
    end

    def expect_json_response_to_include(json)
      json_response = JSON.parse(response.body).with_indifferent_access
      expect(json_response).to include(json)
    end
  end
end
