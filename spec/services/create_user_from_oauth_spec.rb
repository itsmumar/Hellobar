describe CreateUserFromOauth do
  let(:original_email) { 'user@eample.com' }

  let(:omniauth_info) do
    {
      email: original_email,
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

  let(:service) { CreateUserFromOauth.new(omniauth_hash, {}) }

  it 'creates user' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'calls CreateUser service' do
    expect(CreateUser).to receive_service_call.with(a_kind_of(User))
    service.call
  end

  it 'returns the user' do
    user = service.call
    expect(user).to be_a User
    expect(user).to be_persisted
  end
end
