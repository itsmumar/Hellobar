class UserStateCloner
  attr_reader :json, :user, :sites, :site_memberships, :rules, :site_elements, :payment_methods

  def initialize(json)
    @json = JSON.parse(json).with_indifferent_access
    parse_user_state_json
  end

  def parse_user_state_json
    @user = build_user(json[:user])
    @sites = build_sites(json[:sites])
    @site_memberships = build_site_memberships(json[:site_memberships])
    @rules = build_rules(json[:rules])
    @site_elements = build_site_elements(json[:site_elements])
    @payment_methods = build_payment_methods(json[:payment_methods])
  end

  def save
    user.save
    sites.each(&:save)
    site_memberships.each(&:save)
    rules.each(&:save)
    site_elements.each(&:save)
    payment_methods.each(&:save)
  end

  def build_user(user_json)
    user_json.merge! password: 'password'

    user = User.find_or_initialize_by(id: user_json[:id])
    user.attributes = user_json
    user
  end

  def build_sites(sites_json)
    sites_json.map do |site_json|
      site = Site.find_or_initialize_by(id: site_json[:id])
      site.attributes = site_json
      site
    end
  end

  def build_site_memberships(memberships_json)
    memberships_json.map do |membership_json|
      membership = SiteMembership.find_or_initialize_by(id: membership_json[:id])
      membership.attributes = membership_json
      membership
    end
  end

  def build_rules(rules_json)
    rules_json.map do |rule_json|
      rule_json.delete(:description)

      rule = Rule.find_or_initialize_by(id: rule_json[:id])
      rule.attributes = rule_json
      rule
    end
  end

  def build_site_elements(site_elements_json)
    site_elements_json.map do |site_element_json|
      element = SiteElement.find_or_initialize_by(id: site_element_json[:id])
      element.attributes = site_element_json
      element
    end
  end

  def build_payment_methods(payment_methods_json)
    payment_methods_json.map do |payment_method_json|
      payment_method = PaymentMethod.find_or_initialize_by(id: payment_method_json[:id])
      payment_method.attributes = payment_method_json
      payment_method
    end
  end
end
