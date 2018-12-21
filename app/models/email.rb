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
     body + email_footer
  end

  private
  def email_footer
   if address = site.sender_address
     "<p style='background: #f9f9f9;padding: 10px; width: 100%; text-align: center; margin-top: 20px;'>
       #{address.address_one}  #{address.address_two},
       #{address.city}, #{address.state} #{address.postal_code},
       #{address.country}
      </p>"
   end
  end
end
