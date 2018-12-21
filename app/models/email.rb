class Email < ApplicationRecord
  include SearchCop

  search_scope :search do
    attributes :subject
  end

  belongs_to :site
  has_one :campaign, inverse_of: :email
  has_many :sequence_steps, as: :executable, dependent: :destroy, inverse_of: :executable

  validates :from_name, presence: true
  validates :from_email, presence: true, format: { with: Devise.email_regexp }
  validates :subject, presence: true
  validates :body, presence: true

  acts_as_paranoid

  def body_with_footer
    body + site.sender_address.present? ? email_footer : ''
  end

  private

  def email_footer
    "<p style='background: #f9f9f9;padding: 10px; width: 100%; text-align: center; margin-top: 20px;'>
    #{ site.sender_address.address_one }  #{ site.sender_address.address_two },
    #{ site.sender_address.city }, #{ site.sender_address.state } #{ site.sender_address.postal_code },
    #{ site.sender_address.country }
    </p>"
  end
end
