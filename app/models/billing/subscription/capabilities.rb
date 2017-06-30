class Subscription
  class Capabilities
    attr_reader :subscription, :site

    def initialize(subscription, site)
      @subscription = subscription
      @site = site
    end

    def subscription_name
      @subscription.values[:name]
    end

    def acts_as_paid_subscription?
      false
    end

    def remove_branding?
      false
    end

    def closable?
      false
    end

    def custom_targeted_bars?
      false
    end

    def custom_thank_you_text?
      false
    end

    def after_submit_redirect?
      false
    end

    def max_suggestions
      3
    end

    def activate_on_exit?
      false
    end

    def max_site_elements
      10
    end

    def at_site_element_limit?
      @site.site_elements.size >= max_site_elements
    end

    def num_days_improve_data
      90
    end

    def visit_overage
      @subscription ? @subscription.visit_overage : parent_class.defaults[:visit_overage]
    end

    def visit_overage_unit
      @subscription ? @subscription.visit_overage_unit : parent_class.defaults[:visit_overage_unit]
    end

    def visit_overage_amount
      @subscription ? @subscription.visit_overage_amount : parent_class.defaults[:visit_overage_amount]
    end

    def custom_html?
      false
    end

    def content_upgrades?
      false
    end

    def autofills?
      false
    end

    def geolocation_injection?
      false
    end

    def external_tracking?
      false
    end

    def alert_bars?
      false
    end

    def opacity?
      false
    end

    def ==(other)
      self.class == other.class &&
        subscription == other.subscription &&
        site == other.site
    end

    protected

    def parent_class
      self.class.parent
    end
  end
end
