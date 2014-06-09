require 'spec_helper'

describe WordpressPluginController do
  fixtures :all

  it "generates the wordpress plugin without errors" do
    site = sites(:zombo)
    stub_current_user(site.owner)

    get :show, :site_id => site.to_param

    response.should be_success
    response.header["Content-Type"].should == "application/zip"
  end
end
