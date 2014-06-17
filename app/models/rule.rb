class Rule < ActiveRecord::Base
  belongs_to :site

  has_many :bars
  has_many :conditions
end
