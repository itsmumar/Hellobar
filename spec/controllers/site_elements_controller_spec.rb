require 'spec_helper'

describe SiteElementsController do
  fixtures :all

  describe "GET show" do
    it "serializes a site_element to json" do
      element = site_elements(:zombo_traffic)
      stub_current_user(element.site.owner)

      get :show, :site_id => element.site, :id => element, :format => :json

      json = JSON.parse(response.body)

      json["id"].should == element.id
      json["message"].should == element.message
      json["background_color"].should == element.background_color
    end
  end
end
