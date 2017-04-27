require Rails.root.join('config', 'initializers', 'settings.rb')

require './lib/hello/internal_analytics'
require './lib/hello/asset_storage'
require './lib/hello/data_api'
require './lib/hello/data_api_helper'
require './lib/hello/suggested_opportunities'
require './lib/hello/email_digest'
require './lib/hello/email_drip'
require './lib/hello/segments'
require './lib/hello/tracking_param'
require './lib/hello/wordpress_model'
require './lib/hello/wordpress_user'
require './lib/analytics'

require './lib/hello/user_onboarding_campaigns/user_onboarding_campaign'
require './lib/hello/user_onboarding_campaigns/create_a_bar_campaign'
require './lib/hello/user_onboarding_campaigns/configure_your_bar_campaign'
