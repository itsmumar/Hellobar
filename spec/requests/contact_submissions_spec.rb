describe ContactSubmissionsController do
  around { |example| perform_enqueued_jobs(&example) }

  describe 'POST #email_developer' do
    let!(:user) { create :user }
    let!(:site) { create :site, user: user }

    let(:params) { Hash[developer: { email: email }, site_id: site.id] }

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    context 'when developer email is empty' do
      let(:email) { '' }

      it 'redirects to site_path with an error ' do
        post email_developer_contact_submission_path, params

        expect(response).to redirect_to site_path(site)
        expect(flash[:error]).to eql 'Please enter your developer\'s email address.'
      end
    end

    context 'when developer email is string' do
      let(:email) { 'developer@email.com' }

      it 'emails developer' do
        expect(ContactFormMailer)
          .to receive(:contact_developer)
          .with(email, site, user)
          .and_call_original.twice

        post email_developer_contact_submission_path, params

        expect(last_email_sent)
          .to have_subject "Please install Hello Bar on #{ site.host }"
      end

      it 'redirects to site_path with success message' do
        post email_developer_contact_submission_path, params

        expect(response).to redirect_to site_path(site)
        expect(flash[:success]).to eql 'We\'ve sent the installation instructions to your developer!'
      end
    end
  end

  describe 'POST #generic_message' do
    let(:user) { create :user }
    let!(:site) { create :site, user: user }

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    context 'with a site' do
      let(:site) { create :site, user: user }

      let(:params) do
        {
          site_id: site.id,
          message: 'message'
        }
      end

      it 'responds with a redirect to params[:return_to]' do
        post generic_message_contact_submission_path, params

        expect(response).to redirect_to site_path(site)
      end

      it 'sends email' do
        expect(ContactFormMailer)
          .to receive(:generic_message)
          .with('message', user, site)
          .and_call_original.twice

        post generic_message_contact_submission_path, params

        expect(last_email_sent)
          .to have_subject "Contact Form: #{ params[:message][0..50] }"
      end

      context 'with invalid email' do
        before { expect(user).to receive(:email).and_return('invalid').twice }

        it 'does not send email' do
          expect(ContactFormMailer).not_to receive(:generic_message)

          post generic_message_contact_submission_path, params
        end
      end
    end

    context 'without a site' do
      let(:params) do
        {
          message: 'message',
          return_to: root_path
        }
      end

      it 'responds with a redirect to params[:return_to]' do
        post generic_message_contact_submission_path, params

        expect(response).to redirect_to sites_path
      end

      it 'sends email' do
        expect(ContactFormMailer)
          .to receive(:generic_message)
          .with('message', user, nil)
          .and_call_original.twice

        post generic_message_contact_submission_path, params

        expect(last_email_sent)
          .to have_subject "Contact Form: #{ params[:message][0..50] }"
      end
    end
  end
end
