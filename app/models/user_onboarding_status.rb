class UserOnboardingStatus < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true
  validates :status_id, presence: true, uniqueness: { scope: [:user_id] }

  STATUSES = {
    new: 1,
    created_site: 2,
    selected_goal: 3,
    created_element: 4,
    installed_script: 5,
    bought_subscription: 6
  }.freeze
  STATUS_IDS = STATUSES.invert.freeze

  def status_name
    STATUS_IDS[status_id]
  end
end
