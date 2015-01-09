module Hello
  class TrackingParam
    SALT = "imasaltydogyarrr"

    def self.encode_tracker(user_id, action, data)
      sig = Digest::SHA1.hexdigest("#{user_id}#{action}#{data}#{SALT}")[0,8]
      Base64.urlsafe_encode64("#{user_id}///#{action}///#{data}///#{sig}")
    end

    def self.decode_tracker(tracker)
      tracker = CGI.unescape(tracker)
      user_id, action, data, sig = Base64.urlsafe_decode64(tracker).split("///")

      if sig == Digest::SHA1.hexdigest("#{user_id}#{action}#{data}#{SALT}")[0,8]
        return [user_id, action, data]
      else
        raise "Cannot decode tracker: signature does not match"
      end
    end

    def self.track(tracker)
      user_id, tracker_action, tracker_data = decode_tracker(tracker)

      case tracker_action
      when "click"
        # Hello::Tracking.track_event("user", user_id, "Clicked link: #{tracker_data}")
      when "open"
        # Hello::Tracking.track_event("user", user_id, "Opened email: #{tracker_data}")
      end
    rescue => e
      Raven.capture_exception(e)
      Rails.logger.error("Error recording tracker: #{tracker}")
    end
  end
end
