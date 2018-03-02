class Email < ApplicationRecord
  belongs_to :site
  has_one :campaign, inverse_of: :email # rubocop:disable Rails/HasManyOrHasOneDependent

  validates :from_name, presence: true
  validates :from_email, presence: true, format: { with: Devise.email_regexp }
  validates :subject, presence: true
  validates :body, presence: true

  acts_as_paranoid
end
