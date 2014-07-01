require 'spec_helper'

describe SiteElementsController do
  fixtures :all

  describe "GET show" do
    it "serializes a bar to json" do
      bar = bars(:zombo_traffic)
      stub_current_user(bar.site.owner)

      get :show, :site_id => bar.site, :id => bar, :format => :json

      json = JSON.parse(response.body)

      json["site_element"]["id"].should == bar.id
      json["site_element"]["message"].should == bar.message
      json["site_element"]["bar_color"].should == bar.bar_color
    end
  end
end
