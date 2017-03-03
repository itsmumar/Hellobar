module Hello
  class TrackingParam
    SALT = 'imasaltydogyarrr'

    def self.encode_tracker(user_id, event, props)
      props = [props].to_json
      sig = Digest::SHA1.hexdigest("#{user_id}#{event}#{props}#{SALT}")[0,8]
      Base64.urlsafe_encode64("#{user_id}///#{event}///#{props}///#{sig}")
    end

    def self.decode_tracker(tracker)
      tracker = CGI.unescape(tracker)
      user_id, event, props, sig = Base64.urlsafe_decode64(tracker).split('///')

      if sig == Digest::SHA1.hexdigest("#{user_id}#{event}#{props}#{SALT}")[0,8]
        return [user_id, event, JSON.parse(props).first]
      else
        raise 'Cannot decode tracker: signature does not match'
      end
    end

    def self.track(tracker)
      user_id, event, props = decode_tracker(tracker)
      Analytics.track(:user, user_id, event, props)
    rescue => e
      Raven.capture_exception(e)
      Rails.logger.error("Error recording tracker: #{tracker}")
    end
  end
end
