describe ContactListsController, type: :controller do
  let(:site) { create :site, :with_user }
  let(:contact_list) { create(:contact_list, :mailchimp, site: site) }
  let(:subscribers) { [] }

  before do
    stub_current_user(site.owners.first)
    stub_out_ab_variations('Exit Intent Pop-up Based on Bar Goals 2016-06-08') { 'original' }

    allow(Hello::DataAPI).to receive(:contacts).and_return([])
  end

  describe 'GET #index' do
    render_views

    let(:data_api_response) do
      { contact_list.id => 1 }
    end

    before do
      allow(Hello::DataAPI).to receive(:contact_list_totals) { data_api_response }.at_least(1).times
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
    end

    it 'returns success' do
      get :index, site_id: site.id

      expect(response).to be_success
    end

    it "includes service provider's name" do
      get :index, site_id: site.id

      expect(response.body).to include(contact_list.service_provider.name)
    end

    it 'makes a single API call to get num_subscribers for each list' do
      site.contact_lists = [contact_list, contact_list.dup]
      expect(Hello::DataAPI).to receive(:contact_list_totals).once

      get :index, site_id: site
    end
  end

  describe 'GET #show' do
    before do
      allow(Hello::DataAPI).to receive(:lifetime_totals).and_return(nil)
      allow(Hello::DataAPI).to receive(:contact_list_totals).and_return('1' => 20)
    end

    it 'gets contacts from the api at least once' do
      expect(Hello::DataAPI).to receive(:contacts) {
        { contact_list.id => 1 }
      }.at_least(1).times

      get :show, site_id: site, id: contact_list
    end

    it 'is successful' do
      get :show, site_id: site, id: contact_list

      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    let!(:mailchimp) { create :identity, :mailchimp, site: site }

    let(:contact_list_params) do
      {
        name: 'My Contacts',
        provider: '0',
        data: { remote_name: '' },
        double_optin: '0'
      }
    end

    it 'is a 201' do
      post :create, site_id: site, contact_list: contact_list_params

      expect(response.status).to eq(201)
    end

    it 'creates a contact list' do
      expect {
        post :create, site_id: site, contact_list: contact_list_params
      }.to change(ContactList, :count).by(1)
    end

    it 'sets the name correctly' do
      post :create, site_id: site, contact_list: contact_list_params

      new_contact_list = ContactList.last
      expect(new_contact_list.name).to eq('My Contacts')
    end

    context 'when email service provider (esp) uses oauth' do
      let(:contact_list_params) do
        {
          provider: 'mailchimp',
          name: 'My contact list',
          data: { remote_id: '1234', remote_name: 'MailChimp Test' }
        }
      end

      it "defaults the name to 'My contact list'" do
        post :create, site_id: site, contact_list: contact_list_params

        new_contact_list = ContactList.last
        expect(new_contact_list.name).to eq('My contact list')
      end

      it 'adds remote id to data' do
        post :create, site_id: site, contact_list: contact_list_params

        new_contact_list = ContactList.last
        expect(new_contact_list.data['remote_id']).to eq('1234')
      end

      it 'adds remote name to data' do
        post :create, site_id: site, contact_list: contact_list_params

        new_contact_list = ContactList.last
        expect(new_contact_list.data['remote_name']).to eq('MailChimp Test')
      end

      it 'adds the service provider name' do
        post :create, site_id: site, contact_list: contact_list_params

        new_contact_list = ContactList.last
        expect(new_contact_list.service_provider.name).to eq('MailChimp')
      end

      context 'when no identity objects exist' do
        before { site.identities.destroy_all }

        let(:contact_list_params) do
          {
            provider: 'mailchimp',
            name: 'My contact list',
            data: { remote_id: '1234', remote_name: 'Campaign Monitor Test' }
          }
        end

        it 'returns 400 status' do
          post :create, site_id: site, contact_list: contact_list_params

          expect(response.status).to eq 400
        end

        it 'returns 400 status' do
          expect {
            post :create, site_id: site, contact_list: contact_list_params
          }.to change { ContactList.count }.by(0)
        end
      end
    end

    context 'when email service provider (esp) requires embed code' do
      let(:contact_list_params) do
        {
          provider: 'mad_mimi_form',
          name: 'My embed code contact list',
          data: { embed_code: '<script type="text/javascript"></script>' }
        }
      end

      it 'clean-ups the embed code' do
        post :create, site_id: site, contact_list: contact_list_params
        expect(response).not_to be_success
        expect_json_response_to_include('errors' => ['Embed code is invalid'])
      end

      context 'when the embed code is blank' do
        before do
          contact_list_params[:data].delete(:embed_code)
        end

        it 'returns 400 status' do
          post :create, site_id: site, contact_list: contact_list_params

          expect(response.status).to eq(400)
        end

        it 'doesn\'t create a new contact list' do
          expect {
            post :create, site_id: site, contact_list: contact_list_params
          }.to change { ContactList.count }.by(0)
        end
      end
    end
  end

  describe 'PUT #update' do
    context 'when using oauth as email service provider (esp)' do
      let(:contact_list_params) do
        {
          data: { remote_id: '2', remote_name: 'test2' }
        }
      end

      it 'updates the remote id and name' do
        put :update, site_id: site, id: contact_list, contact_list: contact_list_params
        contact_list.reload

        expect(contact_list.data['remote_id']).to eq('2')
      end

      it 'updates the remote name' do
        put :update, site_id: site, id: contact_list, contact_list: contact_list_params
        contact_list.reload

        expect(contact_list.data['remote_name']).to eq('test2')
      end
    end

    context 'when esp has embed_code' do
      let(:contact_list) { create(:contact_list, :embed_code, site: site) }
      let(:embed_code) { '<html><body><iframe><form>Here I am</form></iframe></body></html>' }
      let(:contact_list_params) { { data: { embed_code: embed_code } } }

      it 'keeps the service provider' do
        put :update, site_id: site, id: contact_list, contact_list: contact_list_params
        contact_list.reload

        expect(contact_list.service_provider.name).to eq 'MadMimi'
      end

      it 'changes the embed code' do
        put :update, site_id: site, id: contact_list, contact_list: contact_list_params
        contact_list.reload

        expect(contact_list.data['embed_code']).to eq embed_code
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:valid_params) do
      {
        id: contact_list.id,
        site_id: contact_list.site_id,
        contact_list: { site_elements_action: '0' }
      }
    end

    it 'returns success' do
      delete :destroy, valid_params

      expect(response.status).to eq(200)
    end

    it 'responds with contact list id' do
      delete :destroy, valid_params

      expect_json_response_to_include(id: contact_list.id)
    end

    it 'creates a ContactLists::Destroy object' do
      allow(ContactLists::Destroy).to receive(:run).and_call_original

      delete :destroy, valid_params

      expect(ContactLists::Destroy).to have_received(:run)
    end

    it 'calls destroy with site elements action param' do
      allow(ContactLists::Destroy).to receive(:run).and_return(true)

      delete :destroy, valid_params

      expect(ContactLists::Destroy).to have_received(:run).with(
        contact_list: contact_list,
        site_elements_action: '0'
      )
    end

    context 'when destroy fails' do
      let(:invalid_params) do
        valid_params.tap do |params|
          params[:contact_list][:site_elements_action] = '4'
        end
      end

      before do
        allow_any_instance_of(ContactList)
          .to receive(:site_elements_count).and_return(2)
      end

      it 'returns the contact list' do
        delete :destroy, invalid_params

        expect_json_response_to_include(id: contact_list.id, site_id: contact_list.site_id)
      end

      it 'returns error status' do
        delete :destroy, invalid_params

        expect(response.status).to eq(400)
      end

      it 'responds with the correct error' do
        delete :destroy, invalid_params

        expect_json_to_have_base_error(
          'Must specify an action for existing bars, modals, sliders, and takeovers'
        )
      end
    end
  end
end
