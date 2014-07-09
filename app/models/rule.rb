class Rule < ActiveRecord::Base
  MATCH_ON = {
    all: 'all',
    any: 'any'
  }

  belongs_to :site

  has_many :site_elements
  has_many :conditions

  validates :site, association_exists: true
end
