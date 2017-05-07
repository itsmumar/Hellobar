require 'cleaners/embed_code'

class ServiceProvider
  attr_accessor :client

  include Cleaners::EmbedCode

  class << self
    def [](name)
      provider_config = all_providers[name]
      return nil unless provider_config # invalid provider
      const_name = provider_config['service_provider_class'] || provider_config['name']
      ServiceProviders.const_get(const_name, false)
    end

    def all_providers
      Settings.identity_providers
    end

    def settings
      config[:settings]
    end

    def key
      config[:key]
    end

    def embed_code?
      settings['requires_embed_code'] == true
    end

    def api_key?
      settings['requires_api_key'] == true
    end

    def app_url?
      settings['requires_app_url'] == true
    end

    def oauth?
      settings['oauth'] == true
    end

    private

    def config
      key, value = all_providers.find(&method(:current_provider?))

      { key: key, settings: value }
    end

    def current_provider?(array)
      _key, value = *array
      klass = name.demodulize

      value['service_provider_class'] == klass || value['name'] == klass
    end
  end

  def retry_on_timeout(max: 1)
    original_max = max
    loop do
      raise "Timed out too many times (#{ original_max })" if max == 0
      max -= 1

      begin
        yield(self)
        break # will not break if exception is raised
      rescue Net::OpenTimeout => e
        Rails.logger.error "Caught #{ e }, retrying after 5 seconds"
        sleep 5
      end
    end
  end

  def log(message)
    entry = "#{ Time.current } [#{ self.class.name }] #{ message }"

    if defined? Rails
      Rails.logger.warn entry
    else
      $stdout.puts entry
    end
    nil
  end

  def name
    settings['name']
  end

  delegate :settings, to: :class
  delegate :key, to: :class
  delegate :embed_code?, to: :class
  delegate :oauth?, to: :class
end

module ServiceProviders
end
