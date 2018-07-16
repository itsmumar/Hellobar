describe CreateUser do
  let(:service) { CreateUser.new(user) }
  let(:user) { build :user }

  it 'creates a user' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'creates affiliate information from cookies' do
    cookies = Hash[tap_vid: 'vid', tap_aid: 'aid']

    expect(CreateAffiliateInformation).to receive_service_call.with(user, cookies)

    CreateUser.new(user, cookies).call
  end

  it 'attaches :source and :utm_source to user if they are present in cookies' do
    source = 'promotional'
    utm_source = 'utm_source'
    cookies = Hash[promotional_signup: 'true', utm_source: utm_source]

    created_user = CreateUser.new(user, cookies).call

    expect(created_user.source).to eql source
    expect(created_user.utm_source).to eql utm_source
  end

  it 'track :signed_up event' do
    expect(TrackEvent).to receive_service_call.with(:signed_up, user: user)
    service.call
  end

  it 'returns the user' do
    created_user = service.call

    expect(created_user).to eql user
    expect(created_user).to be_a User
    expect(created_user).to be_persisted
  end
end
