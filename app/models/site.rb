class Site < ActiveRecord::Base
  has_many :rules
  has_many :bars, through: :rules
end
