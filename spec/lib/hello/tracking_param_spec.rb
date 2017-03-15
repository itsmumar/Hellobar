require 'spec_helper'

describe Hello::TrackingParam do
  it 'encodes and decodes a tracker' do
    user_id = '1'
    action = 'click'
    props = { 'url' => 'some url' }
    tracker = Hello::TrackingParam.encode_tracker(user_id, action, props)

    Hello::TrackingParam.decode_tracker(tracker).should == [user_id, action, props]
    URI.escape(tracker).should == tracker
  end

  it 'can handle cgi-escaped params' do
    user_id = '1'
    action = 'click'
    props = { 'url' => 'some url' }
    tracker = Hello::TrackingParam.encode_tracker(user_id, action, props)
    tracker = CGI.escape(tracker)
    Hello::TrackingParam.decode_tracker(tracker).should == [user_id, action, props]
  end

  describe '::track' do
    it 'decodes and records a tracking parameters' do
      tracker = Hello::TrackingParam.encode_tracker('1', 'Clicked', url: 'some url')
      Analytics.should_receive(:track).with(:user, '1', 'Clicked', 'url' => 'some url')
      Hello::TrackingParam.track(tracker)
    end
  end
end
