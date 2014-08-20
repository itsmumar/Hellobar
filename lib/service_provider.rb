class ServiceProvider
  attr_accessor :client

  def log message
    $stdout.puts "#{Time.current} [#{self.class.name}] " + message
  end

  def self.[] name
  	Hashie::Mash.new Hellobar::Settings[:identity_providers][name.to_sym]
  end

  def settings
    klass = self.class.name.demodulize
    Hellobar::Settings[:identity_providers].values.find { |v| v[:service_provider_class] == klass || v[:name] == klass }
  end

  def name
    settings[:name]
  end

  def embed_code?
    settings[:requires_embed_code] === true
  end

  def oauth?
    !embed_code?
  end
end

module ServiceProviders
end
