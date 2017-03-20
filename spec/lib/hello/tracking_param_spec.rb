require 'spec_helper'

describe Hello::TrackingParam do
  it 'encodes and decodes a tracker' do
    user_id = '1'
    action = 'click'
    props = { 'url' => 'some url' }
    tracker = Hello::TrackingParam.encode_tracker(user_id, action, props)

    expect(Hello::TrackingParam.decode_tracker(tracker)).to eq([user_id, action, props])
    expect(URI.escape(tracker)).to eq(tracker)
  end

  it 'can handle cgi-escaped params' do
    user_id = '1'
    action = 'click'
    props = { 'url' => 'some url' }
    tracker = Hello::TrackingParam.encode_tracker(user_id, action, props)
    tracker = CGI.escape(tracker)
    expect(Hello::TrackingParam.decode_tracker(tracker)).to eq([user_id, action, props])
  end

  describe '::track' do
    it 'decodes and records a tracking parameters' do
      tracker = Hello::TrackingParam.encode_tracker('1', 'Clicked', url: 'some url')
      expect(Analytics).to receive(:track).with(:user, '1', 'Clicked', 'url' => 'some url')
      Hello::TrackingParam.track(tracker)
    end
  end
end
