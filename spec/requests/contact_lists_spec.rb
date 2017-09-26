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
      before { allow_any_instance_of(DynamoDB).to receive(:batch_fetch).and_return({}) }

      it 'responds with success' do
        get site_contact_lists_path(site)
        expect(response).to be_successful
      end
    end

    describe 'GET :show' do
      before { allow_any_instance_of(DynamoDB).to receive(:batch_fetch).and_return('edge_contacts' => [contact_list.id.to_s => 1]) }
      before { allow_any_instance_of(DynamoDB).to receive(:fetch).and_return([]) }

      it 'responds with success' do
        get site_contact_list_path(site, contact_list)
        expect(response).to be_successful
      end

      context 'with contact_list_logs' do
        let(:contact_list) { create :contact_list, :aweber, site: site }
        let(:contact_list_log) { create :contact_list_log, contact_list: contact_list }
        let(:completed_contact_list_log) { create :contact_list_log, :completed, contact_list: contact_list }

        before do
          allow_any_instance_of(DynamoDB).to receive(:fetch).and_return([
            { 'email' => contact_list_log.email, 'n' => contact_list_log.name },
            { 'email' => completed_contact_list_log.email, 'n' => completed_contact_list_log.name }
          ])
        end

        it 'includes syncing statuses' do
          get site_contact_list_path(site, contact_list)
          expect(response).to be_successful
          expect(response.body).to include 'Sent'
          expect(response.body).to include 'Error'
        end

        context 'with Hello Bar contact list' do
          let(:contact_list) { create :contact_list, site: site }

          it 'does not include syncing statuses' do
            get site_contact_list_path(site, contact_list)
            expect(response).to be_successful
            expect(response.body).not_to include 'Sent'
            expect(response.body).not_to include 'Error'
          end
        end
      end

      context '.json' do
        it 'responds with success' do
          get site_contact_list_path(site, contact_list, format: :json)
          expect(response).to be_successful
        end
      end
    end

    describe 'GET download', :freeze do
      let(:csv) { "Email,Fields,Subscribed At\nemail@example.com,Name,#{ Time.current }\n" }
      let(:contacts) { [{ email: 'email@example.com', name: 'Name', subscribed_at: Time.current }] }
      let(:total_contacts) { 100 }

      it 'enqueues DownloadContactListJob' do
        expect { get download_site_contact_list_path(site, contact_list) }
          .to have_enqueued_job(DownloadContactListJob)
          .on_queue('hb3_test')
          .with(user, contact_list)
      end

      it 'redirects back' do
        get download_site_contact_list_path(site, contact_list)
        expect(flash[:success])
          .to eql "We will email you the list of your contacts to #{ user.email }." \
                  ' At peak times this can take a few minutes'
        expect(response).to redirect_to site_contact_list_path(site, contact_list)
      end
    end

    describe 'DELETE :destroy' do
      context 'when site_element_action is 1' do
        it 'deletes an existing contact_list' do
          expect {
            delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 1 })
          }.to change { contact_list.reload.deleted? }

          expect(response).to be_successful
        end
      end

      context 'when site_element_action is 0' do
        let!(:site_element) { create :site_element, contact_list: contact_list }

        it 'deletes an existing identity' do
          expect {
            delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 0 })
          }.to change { contact_list.reload.deleted? }

          expect(response).to be_successful
        end

        it 'creates new contact list and updates all bars' do
          expect { delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 0 }) }
            .to change { contact_list.reload.deleted? }
            .and change { site_element.reload.contact_list_id }

          expect(response).to be_successful
        end
      end

      context 'when could not destroy' do
        it 'response with errors' do
          allow(ContactLists::Destroy).to receive(:run).and_return(false)
          delete site_contact_list_path(site, contact_list, contact_list: { site_elements_action: 0 })
          expect(response).not_to be_successful
          expect(response.status).to eql 400
        end
      end
    end

    describe 'POST :create' do
      let!(:identity) { create :identity, site: site }
      let(:last_contact_list) { site.contact_lists.last }

      it 'creates a contact list' do
        expect(TrackEvent).to receive_service_call.with(
          :created_contact_list,
          hash_including(contact_list: anything, user: anything)
        )

        expect {
          post site_contact_lists_path(site, identity_id: identity.id, contact_list: { name: 'Contact List' })
        }.to change { site.contact_lists.count }

        expect(last_contact_list.identity).to eql identity
        expect(response).to be_successful
      end

      context 'when identity is stored in the session' do
        let(:env) { Hash['HTTP_REFERER' => site_contact_lists_path(site)] }

        before do
          OmniAuth.config.add_mock(
            :drip,
            credentials: {},
            extra: { accounts: [{ id: 1 }] }
          )
        end

        it 'stores onniauth data to the session' do
          get '/auth/drip/callback', {}, env

          expect { post site_contact_lists_path(site, contact_list: { name: 'Contact List' }) }
            .to change { site.contact_lists.count }
            .by(1)
            .and change { site.identities.count }
            .by(1)
        end
      end
    end

    describe 'PUT :update' do
      let!(:identity) { create :identity, site: site }
      let(:contact_list) { create :contact_list, site: site }

      def put_update(identity_id: identity.id)
        put site_contact_list_path(site, contact_list),
          identity_id: identity_id, contact_list: { name: 'Updated' }
      end

      it 'updates a contact list' do
        expect { put_update }
          .to change { contact_list.reload.identity }
          .and change { contact_list.reload.name }

        expect(response).to be_successful
      end

      context 'when identity is stored in the session' do
        let(:env) { Hash['HTTP_REFERER' => site_contact_lists_path(site)] }

        before do
          OmniAuth.config.add_mock(
            :drip,
            credentials: {},
            extra: { accounts: [{ id: 1 }] }
          )
        end

        it 'stores onniauth data to the session' do
          get '/auth/drip/callback', {}, env

          expect { put_update identity_id: nil }
            .to change { contact_list.reload.identity }
            .and change { contact_list.reload.name }
        end
      end
    end
  end
end
