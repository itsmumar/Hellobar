class Partner < ActiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }
  validates :website_url, presence: true, url: true
  validates :partner_plan, presence: true

  def partner_plan
    partner_plan_id && PartnerPlan.find(partner_plan_id)
  end

  def partner_plan=(value)
    self.partner_plan_id = value.try(:id)
  end
end
