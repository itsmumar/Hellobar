class Partner < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }
  validates :url, presence: true, url: true
end
