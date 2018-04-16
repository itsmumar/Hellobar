describe CreateUser do
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

  let(:service) { CreateUser.new(omniauth_hash, {}) }

  it 'creates User' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'tracks :signed_up event' do
    expect(TrackEvent).to receive_service_call.with(:signed_up, user: instance_of(User))
    service.call
  end
end
