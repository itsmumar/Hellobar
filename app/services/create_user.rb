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

  def credit_card_signup
    cookies[:cc] == '1'
  end

  def track_event
    TrackEvent.new(:signed_up, event_params).call
  end

  def event_params
    return default_event_params unless promotional_signup?

    default_event_params
      .merge(
        utm_source: utm_source,
        credit_card_signup: credit_card_signup,
        promotional_signup: true
      )
      .reject { |_, value| value.blank? }
  end

  def default_event_params
    Hash[user: user]
  end

  def promotional_signup?
    cookies[:promotional_signup] == 'true'
  end
end
