describe 'ContactList requests' do
  let(:site) { create :site, :with_user }
  let(:contact_list) { create :contact_list, site: site }
  let(:user) { site.owners.last }

  context 'when unauthenticated' do
    describe 'GET :index' do
      it 'responds with a redirect to the login page' do
        get site_contact_lists_path(site)

        expect(response).to be_a_redirect
        expect(response.location).to include 'sign_in'
      end
    end
  end

  context 'when authenticated' do
    before do
      login_as user, scope: :user, run_callbacks: false
    end

    describe 'GET :index' do
      before { allow(Hello::DataAPI).to receive(:contact_list_totals).and_return({}) }

      it 'responds with success' do
        get site_contact_lists_path(site)
        expect(response).to be_successful
      end
    end

    describe 'GET :show' do
      before { allow(Hello::DataAPI).to receive(:contact_list_totals).and_return(contact_list.id.to_s => 1) }
      before { allow(Hello::DataAPI).to receive(:contacts).and_return({}) }

      it 'responds with success' do
        get site_contact_list_path(site, contact_list)
        expect(response).to be_successful
      end

      context '.json' do
        it 'responds with success' do
          get site_contact_list_path(site, contact_list, format: :json)
          expect(response).to be_successful
        end
      end

      context '.csv' do
        it 'redirects to csv downloading' do
          get site_contact_list_path(site, contact_list, format: :csv)
          expect(response).to be_a_redirect
          expect(response.location).to include 'http://mock-hi.hellobar.com/e'
        end
      end
    end

    describe 'DELETE :destroy' do
      context 'when site_element_action is 1' do
        it 'destroys an existing identity' do
          expect {
            delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 1 })
          }.to change { contact_list.reload.destroyed? }

          expect(response).to be_successful
        end
      end

      context 'when site_element_action is 0' do
        let!(:site_element) { create :site_element, contact_list: contact_list }

        it 'destroys an existing identity' do
          expect {
            delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 0 })
          }.to change { contact_list.reload.destroyed? }

          expect(response).to be_successful
        end

        it 'creates new contact list and updates all bars' do
          expect { delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 0 }) }
            .to change { contact_list.reload.destroyed? }
            .and change { site_element.reload.contact_list_id }

          expect(response).to be_successful
        end
      end
    end

    describe 'POST :create' do
      let!(:identity) { create :identity, site: site }
      let(:last_contact_list) { site.contact_lists.last }

      it 'creates contact list' do
        expect {
          post site_contact_lists_path(site, identity_id: identity.id, contact_list: { name: 'Contact List' })
        }.to change { site.contact_lists.count }

        expect(last_contact_list.identity).to eql identity
        expect(response).to be_successful
      end
    end

    describe 'PUT :update' do
      let!(:identity) { create :identity, site: site }
      let(:contact_list) { create :contact_list, site: site }

      it 'updates contact list' do
        expect {
          put site_contact_list_path(site, contact_list, identity_id: identity.id, contact_list: { name: 'Updated' })
        }.to change { contact_list.reload.identity }.and change { contact_list.reload.name }

        expect(response).to be_successful
      end
    end
  end
end
