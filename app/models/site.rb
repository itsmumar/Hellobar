class Site < ActiveRecord::Base
  has_many :rule_sets
  has_many :bars, through: :rule_sets
  has_many :site_memberships, dependent: :destroy
  has_many :users, through: :site_memberships

  before_validation :add_protocol_to_url, :unless => lambda {|s| s.url =~ /^http(s)?:\/\// || s.url.blank?}
  before_validation :strip_path_from_url, :unless => lambda {|s| s.url.blank?}

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

  def add_protocol_to_url
    self.url = "http://#{url}"
  end

  def strip_path_from_url
    match = /^(http(s)?:\/\/)?[\w\.]+/.match(url)
    self.url = match ? match[0] : ""
  end

  def url_format_is_valid
    uri = URI.parse(url)

    if uri.scheme.blank? || uri.host.blank? || uri.host !~ /^\w+\.\w/ || url !~ /^(http(s)?:\/\/)?[\w\.]+$/
      self.errors.add(:url, "is invalid")
    end
  rescue URI::InvalidURIError
    self.errors.add(:url, "is invalid")
  end
end
