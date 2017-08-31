describe ContactSubmissionsController do
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
        .and_return double(deliver_later: true)

      post contact_submissions_path, params
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

    before do
      login_as user, scope: :user, run_callbacks: false
    end

    context 'when developer email is empty' do
      it 'redirects to site_path with an error ' do
        post email_developer_contact_submission_path, developer_email: '', site_id: site.id

        expect(response).to redirect_to site_path(site)
        expect(flash[:error]).to eql 'Please enter your developer\'s email address.'
      end
    end

    context 'when developer email is an array' do
      let(:developer_email) { ['developer@email.com'] }

      it 'emails developer' do
        expect(ContactFormMailer)
          .to receive(:contact_developer)
          .with(developer_email.first, site, user)
          .and_return double(deliver_later: true)

        post email_developer_contact_submission_path, developer_email: developer_email, site_id: site.id
      end

      it 'redirects to site_path with success message' do
        post email_developer_contact_submission_path, developer_email: developer_email, site_id: site.id

        expect(response).to redirect_to site_path(site)
        expect(flash[:success]).to eql 'We\'ve sent the installation instructions to your developer!'
      end
    end

    context 'when developer email is string' do
      let(:developer_email) { 'developer@email.com' }

      it 'emails developer' do
        expect(ContactFormMailer)
          .to receive(:contact_developer)
          .with(developer_email, site, user)
          .and_return double(deliver_later: true)

        post email_developer_contact_submission_path, developer_email: developer_email, site_id: site.id
      end

      it 'redirects to site_path with success message' do
        post email_developer_contact_submission_path, developer_email: developer_email, site_id: site.id

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
          .and_return(double(deliver_later: true))

        post generic_message_contact_submission_path, params
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
          .and_return(double(deliver_later: true))

        post generic_message_contact_submission_path, params
      end
    end
  end
end
