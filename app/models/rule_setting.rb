class RuleSetting < ActiveRecord::Base
  belongs_to :rule

  serialize :exclude_urls
  serialize :include_urls
end
