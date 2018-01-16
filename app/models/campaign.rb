class Campaign < ApplicationRecord
  InvalidTransition = Class.new(StandardError)

  NEW = 'new'.freeze
  SENDING = 'sending'.freeze
  SENT = 'sent'.freeze
  ARCHIVED = 'archived'.freeze
  STATUSES = [NEW, SENDING, SENT, ARCHIVED].freeze

  INVALID_TRANSITION_TO_ARCHIVED = "Campaign can't be archived until it's sent.".freeze

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

  def sent!
    update!(status: SENT, sent_at: Time.current)
  end

  def sent?
    status == SENT
  end

  def archived!
    raise(InvalidTransition, INVALID_TRANSITION_TO_ARCHIVED) unless sent?

    update!(status: ARCHIVED, archived_at: Time.current)
  end

  def archived?
    status == ARCHIVED
  end
end
