class Lead < ActiveRecord::Base
  CHALLENGES = I18n.t('lead.challenges').freeze
  JOB_ROLES = I18n.t('lead.job_roles').freeze
  INDUSTRIES = I18n.t('lead.industries').freeze
  COMPANY_SIZES = I18n.t('lead.company_sizes').freeze
  TRAFFIC_ITEMS = I18n.t('lead.traffic_items').freeze

  belongs_to :user

  validates :industry, :job_role, :company_size, :estimated_monthly_traffic, :first_name, :last_name, :challenge, presence: true
  validates :challenge, inclusion: { in: CHALLENGES.map { |item| item[:value] } }
  validates :phone_number, presence: true, if: :interested
end
