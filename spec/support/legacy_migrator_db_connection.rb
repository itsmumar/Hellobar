# fix for Circle CI
class LegacyMigrator
  class LegacyModel < ActiveRecord::Base
    establish_connection Rails.env.to_sym
  end
end
