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

  describe "PUT 'update'" do
    let!(:updated_contact_list) do
      put :update, site_id: site, id: contact_list, contact_list: contact_list_params
      contact_list.reload
    end

    context 'oauth esp' do
      let(:contact_list_params) do
        {
          data: { remote_id: "2", remote_name: "test2" }
        }
      end

      it 'should have updated the remote id and name' do
        expect(contact_list.data['remote_id']).to eq("2")
        expect(contact_list.data['remote_name']).to eq("test2")
      end
    end

    context 'embed_code esp' do
      let(:contact_list) { contact_lists(:zombo_esp) }
      let(:contact_list_params) do
        {
          data: { embed_code: "asdf" }
        }
      end

      it 'keeps the service provider' do
        expect(contact_list.service_provider.name).to eq "Mad Mimi"
      end
      it 'changes the embed code' do
        expect(contact_list.data['embed_code']).to eq "asdf"
      end
    end
  end
end
