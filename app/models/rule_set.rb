class RuleSet < ActiveRecord::Base
  belongs_to :site

  has_many :bars
  has_many :rules

  serialize :exclude_urls
  serialize :include_urls
end
