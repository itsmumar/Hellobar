class Partner < ActiveRecord::Base
  belongs_to :affiliate_information,
    foreign_key: :affiliate_identifier,
    primary_key: :affiliate_identifier,
    inverse_of: :partner

  validates :email, format: { with: Devise.email_regexp, allow_blank: true }
  validates :affiliate_identifier, presence: true, uniqueness: true
  validates :partner_plan, presence: true

  def self.default_partner_plan
    PartnerPlan.find('growth_30')
  end

  def partner_plan
    partner_plan_id && PartnerPlan.find(partner_plan_id)
  end

  def partner_plan=(value)
    self.partner_plan_id = value.try(:id)
  end
end
