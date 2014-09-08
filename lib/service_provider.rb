require 'cleaners/embed_code'

class ServiceProvider
  attr_accessor :client

  include Cleaners::EmbedCode

  class << self
    def [](name)
      provider_config = all_providers[name.to_sym]
      return nil unless provider_config # invalid provider
      const_name = provider_config[:service_provider_class] || provider_config[:name]
      ServiceProviders.const_get(const_name, false)
    end

    def all_providers
      Hellobar::Settings[:identity_providers]
    end

    def settings
      config[:settings]
    end

    def key
      config[:key]
    end

    def embed_code?
      settings[:requires_embed_code] === true
    end

    def oauth?
      settings[:oauth] === true
    end

    private

    def config
      key, value = all_providers.find(&method(:current_provider?))
      { key: key, settings: value }
    end

    def current_provider?(array)
      key, value = *array
      klass = name.demodulize
      value[:service_provider_class] == klass || value[:name] == klass
    end
  end

  def log message
    $stdout.puts "#{Time.current} [#{self.class.name}] " + message
  end
  
  def name
    settings[:name]
  end

  delegate :settings, to: :class
  delegate :key, to: :class
  delegate :embed_code?, to: :class
  delegate :oauth?, to: :class
end

module ServiceProviders
end
