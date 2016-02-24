require 'spec_helper'

describe SiteElementsController do
  fixtures :all

  describe "GET show" do
    it "serializes a site_element to json" do
      element = site_elements(:zombo_traffic)
      stub_current_user(element.site.owners.first)
      Site.any_instance.stub(has_script_installed?: true)

      get :show, :site_id => element.site, :id => element, :format => :json

      expect_json_response_to_include({
        id: element.id,
        headline: element.headline,
        background_color: element.background_color
      })
    end
  end

  describe "POST create" do
    it "sets the correct error if a rule is not provided" do
      Site.any_instance.stub(:generate_script => true)
      site = sites(:zombo)
      stub_current_user(site.owners.first)

      post :create, :site_id => site.id, :site_element => {:element_subtype => "traffic", :rule_id => 0}

      expect_json_to_have_error(:rule, "can't be blank")
    end
  end

  describe "POST new" do
    it "defaults branding to false if pro" do
      subscription = subscriptions(:pro_subscription)
      stub_current_user(subscription.site.owners.first)

      get :new, :site_id => subscription.site.id, :format => :json

      expect_json_response_to_include({ show_branding: false })
    end

    it "defaults branding to true if free user" do
      subscription = subscriptions(:free_subscription)
      stub_current_user(subscription.site.owners.first)

      get :new, :site_id => subscription.site.id, :format => :json

      json = JSON.parse(response.body)
      expect_json_response_to_include({ show_branding: true })
    end

    it "doesn't push an unsaved element into the site.site_elements association" do
      membership = create(:site_ownership)
      create(:rule, site: membership.site)
      stub_current_user(membership.user)

      get :new, site_id: membership.site.id, format: :json
      expect(assigns(:site_element).site.site_elements.map(&:id)).not_to include(nil)
    end
  end

  describe "POST update" do
    let(:element) {  site_elements(:zombo_traffic) }

    before do
      stub_current_user(element.site.owners.first)

      allow_any_instance_of(Site).to receive(:generate_script)
      allow_any_instance_of(Site).
        to receive(:lifetime_totals).and_return({"1" => [[1,0]]})
    end

    it "creates an updater" do
      expect(SiteElements::Update).to receive(:new).and_call_original

      post :update, valid_params(element)
    end

    it "updates with the params" do
      updater = double(SiteElements::Update, element: element)
      params = valid_params(element)

      expect(SiteElements::Update).to receive(:new).and_return(updater)
      expect(updater).to receive(:run).and_return(true)

      post :update, params
    end

    context "when updating succeeds" do
      it "returns successfully" do
        post :update, valid_params(element)

        expect(response).to be_success
      end

      it "sends json of the updated attributes" do
        post :update, valid_params(element)

        expect_json_response_to_include({
          id: element.id,
          closable: true
        })
      end

      it "sends json of new element if type was changed" do
        email_element = site_elements(:zombo_email)
        params = valid_params(email_element)
        params[:site_element][:element_subtype] = "traffic"

        post :update, params

        json_response = parse_json_response
        expect(json_response[:id]).not_to eq(email_element.id)
      end
    end

    context "when updating fails" do
      it "returns unprocessable_entity" do
        post :update, invalid_params(element)

        expect(response.status).to eq(422)
      end

      def invalid_params(el)
        {
          id: el.id,
          site_id: el.site_id,
          site_element: { border_color: "" }
        }
      end
    end

    def valid_params(el)
      {
        id: el.id,
        site_id: el.site_id,
        site_element: { closable: true }
      }
    end

    def create_successful_updater
      updater = double(SiteElements::Update, update: true)
      expect(SiteElements::Update).to receive(:new).and_return(updater)
      updater
    end

    def create_failing_updater
      updater = double(SiteElements::Update, update: false)
      expect(SiteElements::Update).to receive(:new).and_return(updater)
      updater
    end
  end
end
