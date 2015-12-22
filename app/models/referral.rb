class Referral < ActiveRecord::Base
  STATES = {
    'sent' => 'Invite sent',
    'signed_up' => 'Signed up',
    'installed' => 'Installed'
  }

  belongs_to :user
  validates :state, inclusion: STATES.keys

  def invitation_body
    content = <<-TEXT
If only we could all have friends like #{user.name}. You've been invited to try out a tool called Hello Bar. It allows you to convert more of your website visitors into customers, it grows your following, and it does a bunch of other things for your site.

If you want to try it, you can get it below. Once you install Hello Bar, both you and your friend will enjoy a free month of Hello Bar Pro. (There's also a free version.)
TEXT
    content.html_safe
  end

  def url
    "https://hellobar.com/invite/accept?token=#{user.referral_token}"
  end
end
