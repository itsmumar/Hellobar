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

    context 'signs up for an account' do
      before do
        @site = create :site
        user_params[:site_url] = @site.url
      end

      it 'fails the first time the user enters a site_url if already exists' do
        post users_sign_up_path, registration_form: user_params, signup_with_email: '1'

        expect(response).to render_template('registrations/new')
      end

      it 'should pass if ignore_existing_site is set to true' do
        user_params[:ignore_existing_site] = true
        post users_sign_up_path, registration_form: user_params, signup_with_email: '1'
        site = User.find_by(email: user_params[:email]).sites.last

        expect(response).to redirect_to(new_site_site_element_path(site))
      end
    end
  end
end
