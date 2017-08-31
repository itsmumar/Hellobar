describe Users::ForgotEmailsController do
  describe 'GET #new' do
    it 'responds with success' do
      get new_forgot_email_path
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:params) do
      {
        site_url: 'site.com',
        first_name: 'firstie',
        last_name: 'lastie',
        email: 'la@croix.com'
      }
    end

    it 'delivers the forgot email with the correct parameters' do
      expect(ContactFormMailer)
        .to receive(:forgot_email)
        .with(params)
        .and_return(double(deliver_later: true))

      post forgot_email_path, params
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
