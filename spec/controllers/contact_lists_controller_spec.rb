require 'spec_helper'

describe ContactListsController, "#num_subscribers" do
  fixtures :all

  let(:site) { sites(:zombo) }

  describe "get #index" do
    it "makes a single API call to get num_subscribers for each list" do
      stub_current_user(site.owners.first)

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
    user = stub_current_user(site.owners.first)
    site.contact_lists = [ contact_list ]
    allow_any_instance_of(Identity).to receive(:credentials).and_return("token" => "test")
    allow_any_instance_of(Identity).to receive(:extra).and_return("metadata" => { "api_endpoint" => "test" })
    Hello::DataAPI.stub(:get_contacts).and_return([])
  end

  describe "GET 'index'" do
    render_views

    let(:data_api_response) do
      { contact_list.id => 1 }
    end

    before do
      expect(Hello::DataAPI).to receive(:contact_list_totals).and_return { data_api_response }.at_least(1).times
      Hello::DataAPI.stub(lifetime_totals: nil)
    end

    subject { get :index, site_id: site }
    it { should be_success }
    its(:body) { should include contact_list.service_provider.name }
  end

  describe "GET 'show'" do
    render_views

    let(:data_api_response) do
      { contact_list.id => 1 }
    end

    before do
      expect(Hello::DataAPI).to receive(:get_contacts).and_return { data_api_response }.at_least(1).times
      Hello::DataAPI.stub(lifetime_totals: nil)
      Hello::DataAPI.stub(contact_list_totals: {"1" => 20})
    end

    subject { get :show, site_id: site, id: contact_list }
    it { should be_success }
  end

  describe "POST 'create'" do
    let!(:created_contact_list) do
      expect do
        response = post :create, site_id: site, contact_list: contact_list_params
        expect(response.status).to eq 201
      end.to change { ContactList.count }.by 1

      ContactList.last.tap do |list|
        expect(list).not_to eq(contact_list)
      end
    end

    subject { created_contact_list }

    context 'oauth esp' do
      let(:contact_list_params) do
        {
          provider: "mailchimp",
          name: "My contact list",
          data: { remote_id: "1234", remote_name: "MailChimp Test" }
        }
      end

      its(:name) { should == "My contact list" }
      it 'should add data' do
        expect(subject.data['remote_id']).to eq "1234"
        expect(subject.data['remote_name']).to eq "MailChimp Test"
      end
      it 'adds provider name' do
        expect(subject.service_provider.name).to eq "MailChimp"
      end
    end

    context 'oauth esp with no identity' do
      before { site.identities.destroy_all }

      let(:contact_list_params) do
        {
          provider: "mailchimp",
          name: "My contact list",
          data: { remote_id: "1234", remote_name: "Campaign Monitor Test" }
        }
      end

      it 'should fail' do
        expect do
          response = post :create, site_id: site, contact_list: contact_list_params
          expect(response.status).to eq 400
        end.to change { ContactList.count }.by 0
      end
    end

    context 'embed code esp' do
      let(:contact_list_params) do
        {
          provider: "mad_mimi",
          name: "My embed code contact list",
          data: { embed_code: '<script type="text/javascript"></script>' }
        }
      end

      its(:name) { should == "My embed code contact list" }
      it 'should add data' do
        expect(subject.data['embed_code']).to eq '<script type="text/javascript"></script>'
      end

      context 'embed code is blank' do
        before { contact_list_params[:data].delete(:embed_code) }
        it 'should fail' do
          expect do
            response = post :create, site_id: site, contact_list: contact_list_params
            expect(response.status).to eq 400
          end.to change { ContactList.count }.by 0
        end
      end
    end
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
      let(:contact_list) { contact_lists(:embed_code) }
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
