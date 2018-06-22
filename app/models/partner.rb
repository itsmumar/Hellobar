class Partner < ActiveRecord::Base
  validates :email, format: { with: Devise.email_regexp, allow_blank: true }
  validates :website_url, url: { allow_blank: true }
  validates :affiliate_identifier, presence: true, uniqueness: true
  validates :partner_plan, presence: true

  def partner_plan
    partner_plan_id && PartnerPlan.find(partner_plan_id)
  end

  def partner_plan=(value)
    self.partner_plan_id = value.try(:id)
  end
end
