require 'spec_helper'

describe SiteElementsController do
  fixtures :all

  describe "GET show" do
    it "serializes a site_element to json" do
      element = site_elements(:zombo_traffic)
      stub_current_user(element.site.owner)
      Site.any_instance.stub(has_script_installed?: true)

      get :show, :site_id => element.site, :id => element, :format => :json

      json = JSON.parse(response.body)

      json["id"].should == element.id
      json["headline"].should == element.headline
      json["background_color"].should == element.background_color
    end
  end

  describe "POST create" do
    it "sets the correct error if a rule is not provided" do
      Site.any_instance.stub(:generate_script => true)
      site = sites(:zombo)
      stub_current_user(site.owner)

      post :create, :site_id => site.id, :site_element => {:element_subtype => "traffic", :rule_id => 0}

      json = JSON.parse(response.body)
      json["errors"]["rule"].should == ["can't be blank"]
    end
  end

  describe "POST new" do
    it "defaults branding to false if pro" do
      subscription = subscriptions(:pro_subscription)
      stub_current_user(subscription.site.owner)
      get :new, :site_id => subscription.site.id, :format => :json
      json = JSON.parse(response.body)
      json["show_branding"].should == false
    end

    it "defaults branding to true if free user" do
      subscription = subscriptions(:free_subscription)
      stub_current_user(subscription.site.owner)
      get :new, :site_id => subscription.site.id, :format => :json
      json = JSON.parse(response.body)
      json["show_branding"].should == true
    end
  end
end
