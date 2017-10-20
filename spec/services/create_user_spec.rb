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

  let(:service) { CreateUser.new(omniauth_hash, original_email, {}) }

  it 'creates User' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'tracks :signed_up event' do
    expect(TrackEvent).to receive_service_call.with(:signed_up, user: instance_of(User))
    service.call
  end

  it 'tracks events with Analytics' do
    expect(Analytics)
      .to receive(:track)
      .with(
        :user,
        anything,
        'Configure Your Bar Reminder New Users Only 2016-03-28',
        value: 'original'
      )

    expect(Analytics)
      .to receive(:track)
      .with(:user, anything, 'Signed Up', {})

    expect(Analytics)
      .to receive(:track)
      .with(:user, anything, 'Completed Signup', email: original_email)

    service.call
  end

  context 'when the user is trying to login with a different Google account' do
    let(:service) { CreateUser.new(omniauth_hash, 'user2@eample.com', {}) }

    specify do
      expect { service.call }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          'Validation failed: Please log in with your user2@eample.com Google email'
        )
    end
  end
end
