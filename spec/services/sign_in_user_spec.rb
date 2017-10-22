describe SignInUser do
  let(:omniauth_info) do
    {
      email: 'user@example.com',
      first_name: 'NewFirstName',
      last_name: 'NewLastName'
    }
  end
  let(:omniauth_hash) do
    OmniAuth::AuthHash.new(
      provider: 'google_oauth2', uid: '123545',
      credentials: {
        refresh_token: 'refresh_token',
        access_token: 'access_token',
        expires_at: 1511164844
      },
      info: omniauth_info
    )
  end

  let(:env) do
    {
      'omniauth.auth' => omniauth_hash
    }
  end

  let(:request) { ActionDispatch::Request.new(env) }
  let(:service) { SignInUser.new(request) }
  let(:last_user) { User.last }

  it 'creates a new user' do
    expect(CreateUser)
      .to receive_service_call
      .with(omniauth_hash, nil, ip: '', url: nil)
      .and_return build(:user)

    service.call
  end

  it 'stores email to cookie' do
    service.call
    expect(request.cookie_jar[:login_email]).to eql 'user@example.com'
  end

  context 'when new_site_url presents in session' do
    before { request.session[:new_site_url] = 'new_site_url' }

    it 'returns user and redirect_url' do
      expect(service.call)
        .to match [instance_of(User), '/continue_create_site']
    end
  end

  context 'with existing user' do
    let!(:user) { create :user, email: 'user@example.com' }
    let!(:authentication) { create :authentication, user: user, uid: '123545' }

    it 'updates first_name, last_name, and authentication' do
      expect { service.call }
        .to change { user.reload.first_name }
        .and change { user.reload.last_name }

      expect(User.count).to eql 1
    end

    context 'when new_site_url presents in session' do
      let(:new_site_url) { 'new_site_url' }

      before { request.session[:new_site_url] = new_site_url }

      it 'returns user and redirect_url' do
        expect(service.call)
          .to match [instance_of(User), '/sites/new?url=new_site_url']
      end
    end
  end

  context 'when user is trying to login with a different Google account' do
    before { request.cookies[:login_email] = 'anotheruser@example.com' }

    it 'raises ActiveRecord::RecordInvalid' do
      expect { service.call }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Please log in with your anotheruser@example.com Google email'
        )
    end
  end
end
