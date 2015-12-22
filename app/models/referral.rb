class Referral < ActiveRecord::Base
  belongs_to :site

  def invitation_body(name:)
    content = <<-TEXT
If only we could all have friends like #{name}. You've been invited to try out a tool called Hello Bar. It allows you to convert more of your website visitors into customers, it grows your following, and it does a bunch of other things for your site.

If you want to try it, you can get it below. Once you install Hello Bar, both you and your friend will enjoy a free month of Hello Bar Pro. (There's also a free version.)
TEXT
    content.html_safe
  end
end
