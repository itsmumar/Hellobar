class SiteSerializer < ActiveModel::Serializer
  include SitesHelper

  attributes :id, :url, :contact_lists, :capabilities, :display_name
  attributes :current_subscription, :has_script_installed?, :num_site_elements
  attributes :view_billing, :timezone
  attributes :monthly_pageviews

  has_many :rules, serializer: RuleSerializer

  def monthly_pageviews
    return unless scope # we require a logged in user

    google = scope.authentications.find{|auth| auth.provider == "google_oauth2" }

    if google
      analytics = GoogleAnalytics.new(google.access_token)
      analytics.get_latest_pageviews(object.url)
    end
  rescue Google::Apis::AuthorizationError => e
    Rails.logger.info(e.to_s) # shut up Rubocop
    # user needs to reauthenticate with Google
  end

  def contact_lists
    object.contact_lists.map do |list|
      {
        :id => list.id,
        :name => list.name
      }
    end
  end

  def capabilities
    {
      remove_branding:        object.capabilities.remove_branding?,
      custom_targeted_bars:   object.capabilities.custom_targeted_bars?,
      at_site_element_limit:  object.capabilities.at_site_element_limit?,
      custom_thank_you_text:  object.capabilities.custom_thank_you_text?,
      after_submit_redirect:  object.capabilities.after_submit_redirect?
    }
  end

  def display_name
    object.normalized_url
  end

  def current_subscription
    if object.current_subscription.present?
      SubscriptionSerializer.new(object.current_subscription)
    else
      {}
    end
  end

  def num_site_elements
    object.site_elements.size
  end

  def view_billing
    scope && Permissions.view_bills?(scope, object)
  end
end
