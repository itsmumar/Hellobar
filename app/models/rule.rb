class Rule < ActiveRecord::Base
  belongs_to :site

  has_many :bars

  serialize :exclude_urls
  serialize :include_urls
end
