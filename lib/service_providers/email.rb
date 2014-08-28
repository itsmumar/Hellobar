require 'synchronizers/email'

class ServiceProviders::Email < ServiceProvider
  include Synchronizers::Email

  attr_reader :contact_list, :identity

  def initialize(opts = {})
    @contact_list = opts[:contact_list]
    @identity = opts[:identity]
  end
end
