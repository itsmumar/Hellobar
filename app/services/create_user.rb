class CreateUser
  def initialize(user, cookies = {})
    @user = user
    @cookies = cookies
  end

  # @return User
  def call
    persist_user
    create_affiliate_information
    attach_source_information
    attach_utm_source_information
    track_event
    user
  end

  private

  attr_reader :user, :cookies

  def persist_user
    user.save!
  end

  def create_affiliate_information
    CreateAffiliateInformation.new(user, cookies).call
  end

  def attach_source_information
    user.source = 'promotional' if promotional_signup?
  end

  def attach_utm_source_information
    user.utm_source = utm_source if utm_source
  end

  def promotional_signup?
    cookies[:promotional_signup] == 'true'
  end

  def utm_source
    cookies[:utm_source]
  end

  def track_event
    TrackEvent.new(:signed_up, user: user).call
  end
end
