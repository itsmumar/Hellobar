require 'service_providers/version'
require 'active_support/all'

require 'service_providers/adapters/base'

module ServiceProviders
  module Adapters
    autoload :ActiveCampaign, 'service_providers/adapters/active_campaign'
    autoload :AWeber, 'service_providers/adapters/aweber'
    autoload :CampaignMonitor, 'service_providers/adapters/campaign_monitor'
    autoload :ConstantContact, 'service_providers/adapters/constant_contact'
    autoload :ConvertKit, 'service_providers/adapters/convert_kit'
    autoload :Drip, 'service_providers/adapters/drip'
    autoload :GetResponse, 'service_providers/adapters/get_response'
    autoload :Infusionsoft, 'service_providers/adapters/infusionsoft'
    autoload :MadMimi, 'service_providers/adapters/mad_mimi'
    autoload :MailChimp, 'service_providers/adapters/mail_chimp'
    autoload :Maropost, 'service_providers/adapters/maropost'
    autoload :VerticalResponse, 'service_providers/adapters/vertical_response'
  end

  mattr_accessor :config
  self.config = ActiveSupport::OrderedOptions.new { |hash, k| hash[k] = ActiveSupport::OrderedOptions.new }

  def self.configure
    yield config
  end
end
