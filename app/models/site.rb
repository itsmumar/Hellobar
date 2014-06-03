class Site < ActiveRecord::Base
  has_many :rules
  has_many :bars, through: :rules
  has_many :site_memberships, dependent: :destroy
  has_many :users, through: :site_memberships
end
