class CreateAffiliateInformation
  def initialize user, cookies
    @user = user
    @cookies = cookies
  end

  def call
    return unless affiliate_cookies_present?

    create_affiliate_information
  end

  private

  attr_reader :user, :cookies

  def affiliate_cookies_present?
    cookies[:tap_aid].present? && cookies[:tap_vid].present?
  end

  def create_affiliate_information
    AffiliateInformation.create! affiliate_params
  end

  def affiliate_params
    {
      user: user,
      visitor_identifier: cookies[:tap_vid],
      affiliate_identifier: cookies[:tap_aid]
    }
  end
end
