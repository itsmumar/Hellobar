class ServiceProvider
  attr_accessor :client

  class << self
    def [](name)
      Hashie::Mash.new providers[name.to_sym]
    end

    def providers
      Hellobar::Settings[:identity_providers]
    end
  end

  def log message
    $stdout.puts "#{Time.current} [#{self.class.name}] " + message
  end

  def settings
    config[:settings] 
  end

  def key
    config[:key]
  end

  def name
    settings[:name]
  end

  def embed_code?
    settings[:requires_embed_code] === true
  end

  def oauth?
    settings[:oauth] === true
  end

  private

  def config
    key, value = self.class.providers.find(&method(:current_provider?))
    { key: key, settings: value }
  end

  def current_provider?(array)
    key, value = *array
    klass = self.class.name.demodulize
    value[:service_provider_class] == klass || value[:name] == klass
  end
end

module ServiceProviders
end
