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

      context '.csv', :freeze do
        let(:csv) { "Email,Fields,Subscribed At\nemail@example.com,Name,#{ Time.current }\n" }
        let(:contacts) { [{ email: 'email@example.com', name: 'Name', subscribed_at: Time.current }] }
        let(:total_contacts) { 100 }

        before do
          expect(FetchContactListTotals)
            .to receive_service_call
            .with(contact_list.site, id: contact_list.id.to_s)
            .and_return(total_contacts)
        end

        it 'enqueues ExportNotifications mailer' do
          expect(ExportNotifications).to receive(:send_contacts_csv).and_call_original
          expect { get site_contact_list_path(site, contact_list, format: :csv) }
            .to have_enqueued_job.on_queue('test_mailers')
        end

        it 'redirects back' do
          get site_contact_list_path(site, contact_list, format: :csv)
          expect(flash[:success])
            .to eql "You will be emailed a CSV of #{ total_contacts } users to #{ user.email }." \
                    ' At peak times this can take a few minutes'
          expect(response).to redirect_to site_contact_list_path(site, contact_list)
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
    end

    describe 'PUT :update' do
      let!(:identity) { create :identity, site: site }
      let(:contact_list) { create :contact_list, site: site }

      it 'updates a contact list' do
        expect {
          put site_contact_list_path(site, contact_list, identity_id: identity.id, contact_list: { name: 'Updated' })
        }.to change { contact_list.reload.identity }.and change { contact_list.reload.name }

        expect(response).to be_successful
      end
    end
  end
end
