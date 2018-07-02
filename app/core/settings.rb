module Settings
  class << self
    def new
      raise NoMethodError
    end

    # Proxy Rails.application.secrets
    def method_missing name, *args, &block
      Rails.application.secrets.public_send name, *args, &block
    end

    def respond_to_missing? _name, _include_private = false
      true
    end
  end
end
