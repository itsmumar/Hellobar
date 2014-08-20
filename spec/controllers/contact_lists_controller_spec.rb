require 'spec_helper'

describe ContactListsController, "#num_subscribers" do
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

describe ContactListsController, type: :controller do
  fixtures :all

  let(:site) { sites(:zombo) }
  let(:contact_list) { contact_lists(:zombo) }
  let(:subscribers) { [] } # no subscribers for now

  before do
    user = stub_current_user(site.owner)
    site.contact_lists = [ contact_list ]
    allow_any_instance_of(Identity).to receive(:credentials).and_return("token" => "test")
    allow_any_instance_of(Identity).to receive(:extra).and_return("metadata" => { "api_endpoint" => "test" })
    allow(Hello::EmailData).to receive(:get_emails).and_return { [] }
    allow(Hello::EmailData).to receive(:num_emails).and_return { subscribers.count }
  end

  describe "GET 'index'" do
    render_views

    subject { get :index, site_id: site }
    it { should be_success }
    its(:body) { should include contact_list.service_provider.name }
  end

  describe "GET 'show'" do
    render_views
    
    subject { get :show, site_id: site, id: contact_list }
    it { should be_success }
    its(:body) { should include "Syncing contacts with #{contact_list.provider}" }
  end
end
