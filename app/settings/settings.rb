module Settings
  class << self
    # Proxy Rails.application.secrets
    def method_missing name, *args, &block
      if name.to_s != 'new'
        Rails.application.secrets.public_send name, *args, &block
      else
        super
      end
    end

    def respond_to_missing? name, _include_private = false
      name.to_s != 'new' ? true : false
    end
  end
end
