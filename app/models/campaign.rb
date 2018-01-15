class Campaign < ApplicationRecord
  NEW = 'new'.freeze
  SENT = 'sent'.freeze
  ARCHIVED = 'archived'.freeze
  STATUSES = [NEW, SENT, ARCHIVED].freeze

  acts_as_paranoid

  has_one :site, through: :contact_list, dependent: :nullify
  belongs_to :contact_list

  validates :site, presence: true
  validates :contact_list, presence: true
  validates :name, presence: true
  validates :from_name, presence: true
  validates :from_email, presence: true, format: { with: Devise.email_regexp }
  validates :subject, presence: true
  validates :body, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  def statistics
    FetchCampaignStatistics.new(self).call
  end

  def sent?
    status == SENT
  end

  def archived!
    update(status: ARCHIVED, archived_at: Time.current)
  end

  def archived?
    status == ARCHIVED
  end
end
