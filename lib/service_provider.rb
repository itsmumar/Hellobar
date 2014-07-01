class ServiceProvider
  attr_accessor :client

  def log message
    $stdout.puts "#{Time.current} [#{self.class.name}] " + message
  end

  def self.[] name
  	Hashie::Mash.new Hellobar::Settings[:identity_providers][name.to_sym]
  end
end

module ServiceProviders
end
