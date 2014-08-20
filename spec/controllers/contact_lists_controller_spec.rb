require 'spec_helper'

describe ContactListsController do
  fixtures :all

  let(:site) { sites(:zombo) }

  describe "get #index" do
    it "makes a single API call to get num_subscribers for each list" do
      stub_current_user(site.owner)

      Hello::DataAPI.should_receive(:contact_list_totals).once

      get :index, :site_id => site

      assigns(:contact_lists).count.should be > 1
    end
  end
end
