class LegacyMigrator
  class LegacyModel < ActiveRecord::Base
    self.abstract_class = true

    begin
      establish_connection "legacy_#{ Rails.env }".to_sym
    rescue ActiveRecord::AdapterNotSpecified
      Rails.logger.warn "database legacy_#{ Rails.env } does not exist"
    end
  end
end

require_relative './legacy_account'
require_relative './legacy_admin'
require_relative './legacy_bar'
require_relative './legacy_goal'
require_relative './legacy_identity'
require_relative './legacy_identity_integration'
require_relative './legacy_membership'
require_relative './legacy_site'
require_relative './legacy_user'
