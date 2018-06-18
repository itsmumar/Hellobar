class Partner < ActiveRecord::Base
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: Devise.email_regexp }
  validates :website_url, presence: true, url: true
  validates :plan, presence: true

  def plan
    plan_id && PartnerPlan.find(plan_id)
  end

  def plan=(value)
    self.plan_id = value.try(:id)
  end
end
