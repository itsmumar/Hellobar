describe 'Users registration' do
  describe 'POST #create' do
    let(:email) { 'user@example.com' }
    let(:user_params) do
      {
        site_url: 'http://mysite.com',
        email: email,
        password: 'password',
        accept_terms_and_conditions: '1'
      }
    end

    it 'creates a user with affiliate information' do
      expect(CreateAffiliateInformation).to receive_service_call

      post users_sign_up_path, registration_form: user_params, signup_with_email: '1'

      user = User.find_by email: email

      expect(user).to be_present
    end
  end
end
