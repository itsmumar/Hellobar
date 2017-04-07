class Lead < ActiveRecord::Base
  CHALLENGES = %w(more_emails more_sales conversion_optimization).freeze

  belongs_to :user

  validates :industry, :job_role, :company_size, :estimated_monthly_traffic, :first_name, :last_name, :challenge, presence: true
  validates :challenge, inclusion: { in: CHALLENGES }
  validates :phone_number, presence: true, if: :interested
end
