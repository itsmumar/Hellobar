class Hello::WordpressUser < Hello::WordpressModel
  self.table_name = 'hbwp_users'
  PRO_TRIAL_PERIOD = 14.days

  attr_reader :password # to conform with User so we can reuse forms

  def self.email_exists?(email)
    find_by_email(email).present?
  end

  def self.find_by_email(email)
    @@connected ? where(['user_email = ? or user_login = ?', email, email]).first : nil
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.error('Wordpress database configured in database.yml does not exist')
    nil
  end

  def self.authenticate(email, password, skip_password_check = false)
    user = where(['user_email = ? or user_login = ?', email, email]).first

    if skip_password_check
      user
    else
      user && Phpass.new.check(password, user.user_pass) ? user : nil
    end
  end

  def email
    return user_email if user_email.present?
    return user_login if user_login.present?
  end

  def bars
    unless @bars
      all_bars = Hello::WordpressBar.where(post_author: id, post_type: 'hellobar')

      @bars = all_bars.select do |bar|
        if bar.post_parent.present? && bar.post_parent != 0
          parent = all_bars.find { |b| b.id == bar.post_parent }
          parent && parent.post_status != 'trash' && bar.post_status != 'trash'
        else
          bar.post_status != 'trash'
        end
      end
    end
    @bars
  end

  def convert_to_user
    User.new(
      email: email,
      encrypted_password: user_pass,
      wordpress_user_id: id
    ).tap { |u| u.save(validate: false) }
  end

  def converted?
    User.where(email: user_email).first ? true : false
  end

  def force_convert
    # Get all the old bars
    old_bars = bars
    # Convert self to user
    user = convert_to_user
    # Create a temporary site (since we don't know their actual URL)
    site = Site.new(url: 'mysite.com')
    site.save!
    # Create the default URLs
    site.create_default_rules
    # Associate the site to the user
    SiteMembership.create!(site: site, user: user)
    # Create a free trial subscription
    subscription = Subscription::Pro.new(schedule: 'monthly')
    site.change_subscription(subscription, nil, Hello::WordpressUser::PRO_TRIAL_PERIOD)
    # Add all the bars
    new_bars = []
    old_bars.each do |bar|
      new_bars << bar.convert_to_site_element!(site.rules.first)
    end
    # Return the user
    [user, site, new_bars]
  end

  def is_pro_user?
    Hello::WordpressUserMeta.where(user_id: id, meta_key: 'hellobar_vip_user').first.try(:meta_value) == '1' ||
      !Hello::WordpressUserMeta.where(user_id: id, meta_key: 'hbwp_s2member_subscr_id').first.try(:meta_value).nil?
  end

  def wordpress_user?
    true
  end
end
