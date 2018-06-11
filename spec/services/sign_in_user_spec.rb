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

  it 'creates a new user and stores affiliate information' do
    expect(CreateUserFromOauth)
      .to receive_service_call
      .with(omniauth_hash)
      .and_return build(:user)

    expect(CreateAffiliateInformation).to receive_service_call

    service.call
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

    context 'when authentication not found' do
      before { authentication.destroy }

      it 'creates new authentication' do
        expect { service.call }
          .to change { user.authentications.count }.by(1)
      end

      it 'creates authentication with proper attributes' do
        service.call
        authentication = user.authentications.last

        expect(authentication.provider).to eq(omniauth_hash.provider)
        expect(authentication.refresh_token).to eq(omniauth_hash.credentials.refresh_token)
        expect(authentication.access_token).to eq(omniauth_hash.credentials.token)
        expect(authentication.expires_at).to be_present
      end
    end
  end
end
