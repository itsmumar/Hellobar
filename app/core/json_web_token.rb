class JsonWebToken
  class << self
    def encode payload
      JWT.encode payload, secret
    end

    def decode token
      HashWithIndifferentAccess.new JWT.decode(token, secret).first
    end

    private

    def secret
      Settings.secret_key_base
    end
  end
end
