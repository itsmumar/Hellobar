class Referral < ActiveRecord::Base
  STATES = {
    'sent' => 'Invite sent',
    'signed_up' => 'Signed up',
    'installed' => 'Installed'
  }

  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :state, inclusion: STATES.keys
  validates :sender_id, presence: true
  validates :email, presence: true

  def url
    "https://hellobar.com/invite/accept?token=#{sender.referral_token}"
  end

  def set_standard_body
    self.body = I18n.t("referral.standard_body", name: sender.name)
  end
end
