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

  it 'returns the user' do
    created_user = service.call

    expect(created_user).to eql user
    expect(created_user).to be_a User
    expect(created_user).to be_persisted
  end

  it 'track :signed_up event' do
    expect(TrackEvent).to receive_service_call.with(:signed_up, user: user)
    service.call
  end

  context 'when promotional signup' do
    it 'tracks :signed_up event with promotional signup params' do
      utm_source = 'utm_source'
      cookies = Hash[promotional_signup: 'true', utm_source: utm_source]

      expect(TrackEvent).to receive_service_call
        .with :signed_up, user: user, promotional_signup: true, utm_source: utm_source

      CreateUser.new(user, cookies).call
    end
  end

  context 'when credit card is required' do
    let(:utm_source) { 'utm_source' }
    let(:cookies) { Hash[promotional_signup: 'true', utm_source: utm_source, cc: '1'] }

    it 'tracks :signed_up event with promotional signup params' do
      expect(TrackEvent).to receive_service_call
        .with(
          :signed_up,
          user: user,
          promotional_signup: true,
          utm_source: utm_source,
          credit_card_signup: true
        )

      CreateUser.new(user, cookies).call
    end
  end

  context 'when credit card is not required' do
    let(:utm_source) { 'utm_source' }
    let(:cookies) { Hash[promotional_signup: 'true', utm_source: utm_source, cc: 'whatever'] }

    it 'tracks :signed_up event with promotional signup params' do
      expect(TrackEvent).to receive_service_call
        .with(
          :signed_up,
          user: user,
          promotional_signup: true,
          utm_source: utm_source
        )

      CreateUser.new(user, cookies).call
    end
  end
end
