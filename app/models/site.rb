class Site < ActiveRecord::Base
  has_many :rule_sets
  has_many :bars, through: :rule_sets
  has_many :site_memberships, dependent: :destroy
  has_many :users, through: :site_memberships

  before_validation :standardize_url

  validates_with UrlValidator, url_field: :url

  def owner
    if membership = site_memberships.where(:role => "owner").first
      membership.user
    else
      nil
    end
  end

  def has_script_installed?
    false
  end


  private

  def standardize_url
    url = Addressable::URI.heuristic_parse(self.url)

    self.url = "#{url.scheme}://#{url.normalized_host}"
  end
end
