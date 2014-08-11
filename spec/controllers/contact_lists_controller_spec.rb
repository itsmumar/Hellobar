require 'spec_helper'

describe ContactListsController do
  fixtures :all

  describe "GET #inline" do
    it "returns the contents of the inflight contact list object stored in the session" do
      user = stub_current_user(users(:joey))
      site = sites(:zombo)

      controller.session[:inflight_contact_list_params] = {:id => 123, :name => "my contact list"}

      get :inflight, :site_id => site.id, :format => :json

      json = JSON.parse(response.body)

      json["id"].should == 123
      json["name"].should == "my contact list"
    end

    it "returns a 404 on any subsequent attempts to retrieve the inflight contact list" do
      user = stub_current_user(users(:joey))
      site = sites(:zombo)

      controller.session[:inflight_contact_list_params] = {:id => 123, :name => "my contact list"}

      get :inflight, :site_id => site.id, :format => :json
      response.code.should == "200"

      get :inflight, :site_id => site.id, :format => :json
      response.code.should == "404"
    end
  end
end
