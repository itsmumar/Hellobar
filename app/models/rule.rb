class Rule < ActiveRecord::Base
  MATCH_ON = {
    all: 'all',
    any: 'any'
  }

  belongs_to :site

  has_many :bars
  has_many :conditions
end
