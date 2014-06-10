class LegacyMigrator
  class LegacyModel < ActiveRecord::Base
    self.abstract_class = true
    establish_connection Rails.env.test? ? :test : "legacy_#{Rails.env}".to_sym
  end
end

require_relative './legacy_account'
require_relative './legacy_bar'
require_relative './legacy_goal'
require_relative './legacy_membership'
require_relative './legacy_site'
require_relative './legacy_user'
