class CreateUser
  def initialize(user, cookies = {})
    @user = user
    @cookies = cookies
  end

  # @return User
  def call
    persist_user
    create_affiliate_information
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

  def utm_source
    cookies[:utm_source]
  end

  def track_event
    TrackEvent.new(:signed_up, event_params).call
  end

  def event_params
    if promotional_signup? && utm_source
      default_event_params.merge promotional_signup: true, utm_source: utm_source
    elsif promotional_signup?
      default_event_params.merge promotional_signup: true
    else
      default_event_params
    end
  end

  def default_event_params
    Hash[user: user]
  end

  def promotional_signup?
    cookies[:promotional_signup] == 'true'
  end
end
