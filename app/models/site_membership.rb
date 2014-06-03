class SiteMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :site

  validates :user_id, :uniqueness => {:scope => :site_id}
end
