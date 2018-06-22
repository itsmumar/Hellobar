describe CreateUser do
  let(:service) { CreateUser.new(user) }
  let(:user) { build :user }
  let(:cookies) { Hash[tap_vid: 'vid', tap_aid: 'aid'] }

  it 'creates a user' do
    expect { service.call }.to change(User, :count).by(1)
  end

  it 'creates affiliate information from cookies' do
    expect(CreateAffiliateInformation).to receive_service_call.with(user, cookies)

    CreateUser.new(user, cookies).call
  end

  it 'track :signed_up event' do
    expect(TrackEvent).to receive_service_call.with(:signed_up, user: user)
    service.call
  end

  it 'returns the user' do
    user = service.call
    expect(user).to eql user
    expect(user).to be_a User
    expect(user).to be_persisted
  end
end
