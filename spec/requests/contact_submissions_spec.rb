describe ContactSubmissionsController do
  around { |example| perform_enqueued_jobs(&example) }

  describe 'GET #new' do
    it 'responds with success' do
      get new_contact_submission_path

      expect(response).to be_success
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        contact_submission: {
          email: 'kaitlen@hellobar.com',
          name: 'Kaitlen',
          message: 'Hi Kaitlen'
        }
      }
    end

    it 'redirects to new_contact_submission_path' do
      post contact_submissions_path, params

      expect(response).to redirect_to new_contact_submission_path
    end

    it 'sends email' do
      expect(ContactFormMailer)
        .to receive(:guest_message)
        .with(params[:contact_submission])
        .and_call_original.twice

      post contact_submissions_path, params

      expect(last_email_sent)
        .to have_subject "Contact Form: #{ params[:contact_submission][:message][0..50] }"
    end

    context 'when the spam catcher field "blank" is not blank' do
      it 'raises an error' do
        expect { post contact_submissions_path, blank: 'not blank' }
          .to raise_error(ActionController::RoutingError)
      end
    end
  end

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
          .to have_subject "Please install Hello Bar on #{ site.normalized_url }"
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

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    context 'with a site' do
      let(:site) { create :site, user: user }

      let(:params) do
        {
          site_id: site.id,
          message: 'message',
          return_to: root_path
        }
      end

      it 'responds with a redirect to params[:return_to]' do
        post generic_message_contact_submission_path, params

        expect(response).to redirect_to params[:return_to]
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

        expect(response).to redirect_to params[:return_to]
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
