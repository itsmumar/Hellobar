require "spec_helper"

describe Hello::TrackingParam do
  fixtures :all

  it "encodes and decodes a tracker" do
    user_id = "1"
    action = "click"
    data = "some url"
    tracker = Hello::TrackingParam.encode_tracker(user_id, action, data)

    Hello::TrackingParam.decode_tracker(tracker).should == [user_id, action, data]
    URI::escape(tracker).should == tracker
  end

  it "can handle cgi-escaped params" do
    tracker = "MTIvLy9vcGVuLy8vRHJpcCAxLy8vMDk0MDhmZjk%3D"
    Hello::TrackingParam.decode_tracker(tracker).should == ["12", "open", "Drip 1"]
  end

  describe "::track" do
    it "decodes and records a tracking parameters" do
      tracker = Hello::TrackingParam.encode_tracker("1", "click", "some url")
      Hello::Tracking.should_receive(:track_event).with("user", "1", "Clicked link: some url")

      Hello::TrackingParam.track(tracker)
    end
  end
end
