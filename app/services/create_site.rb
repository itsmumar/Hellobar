class CreateSite
  class DuplicateURLError < StandardError
    attr_reader :existing_site

    def initialize(existing_site)
      @existing_site = existing_site
      super 'Url is already in use.'
    end
  end

  def initialize(site, current_user, referral_token)
    @site = site
    @current_user = current_user
    @referral_token = referral_token
  end

  def call
    check_for_duplicate!

    Site.transaction do
      site.owners << current_user
      site.save!
      site.create_default_rules
    end

    TrackEvent.new(:created_site, site: site, user: current_user).call

    Referrals::HandleToken.run(user: current_user, token: referral_token)
    DetectInstallType.new(site).call
    ChangeSubscription.new(site, subscription: 'free', schedule: 'monthly').call
  end

  private

  attr_reader :site, :current_user, :referral_token

  def check_for_duplicate!
    existing_site = Site.by_url_for(current_user, url: site.url)
    raise DuplicateURLError, existing_site if existing_site
  end
end
