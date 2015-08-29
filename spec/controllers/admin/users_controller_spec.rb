require 'spec_helper'

describe Admin::UsersController do
  fixtures :all

  before(:each) do
    @admin = admins(:joey)
  end

  describe "GET #index" do
    it "allows admins to search users by site URL" do
      stub_current_admin(@admin)

      get :index, :q => "zombo.com"

      assigns(:users).include?(sites(:zombo).owners.first).should be_true
    end

    it "finds deleted users" do
      stub_current_admin(@admin)
      user = User.create email: "test@test.com", password: 'supers3cr37'
      user.destroy
      get :index, :q => "test"

      assigns(:users).include?(user).should be_true
    end
  end

  describe "GET #show" do
    before do
      stub_current_admin(@admin)
    end

    it "shows the specified user" do
      user = users(:joey)
      get :show, :id => user.id

      assigns(:user).should == user
    end

    it "shows a deleted users" do
      user = User.create email: "test@test.com", password: 'supers3cr37'
      user.destroy
      get :show, :id => user.id

      assigns(:user).should == user
    end
  end

  describe "POST #impersonate" do
    it "allows the admin to impersonate a user" do
      stub_current_admin(@admin)

      post :impersonate, :id => users(:joey)

      controller.current_user.should == users(:joey)
    end
  end

  describe "DELETE #unimpersonate" do
    it "allows the admin to stop impersonating a user" do
      stub_current_admin(@admin)

      post :impersonate, :id => users(:joey)

      controller.current_user.should == users(:joey)

      delete :unimpersonate

      controller.current_user.should be_nil
    end
  end

  describe "DELETE #destroy" do
    it "allows the admin to (soft) destroy a user" do
      stub_current_admin(@admin)
      user = users(:wootie)

      delete :destroy, :id => user

      User.only_deleted.should include(user)
    end
  end

  describe "POST #regenerate_script" do
    before do
      stub_current_admin(@admin)
    end

    context "when the site exists" do
      let(:site) { sites(:zombo) }
      let(:user) { site.owners.first }

      before do
        Hello::DataAPI.stub(:lifetime_totals => nil)

        allow(User).to receive(:find).and_return(user)
        allow(user.sites).to receive(:where).and_return([site])

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
      post :regenerate_script, { user_id: user.id, site_id: site_id }
    end

    def expect_json_response_to_include(json)
      json_response = JSON.parse(response.body).with_indifferent_access
      expect(json_response).to include(json)
    end
  end
end
