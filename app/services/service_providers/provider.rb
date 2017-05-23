module ServiceProviders
  class Provider
    mattr_accessor :config
    self.config = ActiveSupport::OrderedOptions.new { |hash, k| hash[k] = ActiveSupport::OrderedOptions.new }

    def self.configure
      yield config
    end
  end
end
