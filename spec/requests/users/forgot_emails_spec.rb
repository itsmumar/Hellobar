describe Users::ForgotEmailsController do
  describe 'GET #new' do
    it 'responds with success' do
      get new_forgot_email_path
      expect(response).to be_successful
    end
  end

  around { |example| perform_enqueued_jobs(&example) }

  describe 'POST #create' do
    let(:params) do
      {
        site_url: 'site.com',
        first_name: 'FirstName',
        last_name: 'LastName',
        email: 'email@example.com'
      }
    end

    it 'delivers the forgot email with the correct parameters' do
      post forgot_email_path, params

      expect(last_email_sent)
        .to have_subject 'Customer Support: Forgot Email FirstName LastName email@example.com'
    end

    it 'redirects to the new_forgot_email_path' do
      post forgot_email_path, params

      expect(response).to redirect_to new_forgot_email_path
    end

    it 'flashes a notice to the user' do
      post forgot_email_path, params

      expect(flash[:notice]).to be_present
    end
  end
end
