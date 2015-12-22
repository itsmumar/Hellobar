class Referral < ActiveRecord::Base
  STATES = {
    'sent' => 'Invite sent',
    'signed_up' => 'Signed up',
    'installed' => 'Installed'
  }

  belongs_to :user
  validates :state, inclusion: STATES.keys
  validates :user_id, presence: true
  validates :email, presence: true

  def url
    "https://hellobar.com/invite/accept?token=#{user.referral_token}"
  end

  def set_standard_body
    self.body = I18n.t("referral.standard_body", name: user.name)
  end
end
