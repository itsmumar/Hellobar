class SenderAddress < ActiveRecord::Base
  belongs_to :site

  validates :site_id, :address_one, :city, :state, :postal_code, presence: true
  validates :state, presence: true, if: -> { country == 'US' }
end
