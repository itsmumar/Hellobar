describe Hello::TrackingParam do
  let(:user_id) { '1' }
  let(:action) { 'click' }
  let(:props) { { 'url' => 'some url' } }
  let(:tracker) { Hello::TrackingParam.encode_tracker(user_id, action, props) }

  it 'deletes \n' do
    expect(Hello::TrackingParam.decode_tracker(tracker + "\n/")).to eql [user_id, action, props]
  end

  it 'deletes trailing slash' do
    expect(Hello::TrackingParam.decode_tracker(tracker + '/')).to eql [user_id, action, props]
  end

  it 'encodes and decodes a tracker' do
    expect(Hello::TrackingParam.decode_tracker(tracker)).to eql [user_id, action, props]
    expect(URI.escape(tracker)).to eq(tracker)
  end

  it 'can handle cgi-escaped params' do
    expect(Hello::TrackingParam.decode_tracker(CGI.escape(tracker))).to eql [user_id, action, props]
  end

  describe '.track' do
    it 'decodes and records a tracking parameters' do
      tracker = Hello::TrackingParam.encode_tracker(user_id, action, props)
      expect(Analytics).to receive(:track).with(:user, user_id, action, props)
      Hello::TrackingParam.track(tracker)
    end
  end
end
