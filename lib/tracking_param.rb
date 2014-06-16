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
  end
end
