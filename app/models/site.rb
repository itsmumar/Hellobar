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

  # TODO: implement
  def has_script_installed?
    false
  end

  def script_url
    "s3.amazonaws.com/#{Hellobar::Settings[:s3_bucket]}/#{script_name}"
  end

  def script_name
    raise "script_name requires ID" unless persisted?
    "#{Digest::SHA1.hexdigest("bar#{id}cat")}.js"
  end

  def script_content(compress = true)
    ScriptGenerator.new(self, :compress => compress).generate_script
  end


  private

  def standardize_url
    url = Addressable::URI.heuristic_parse(self.url)

    self.url = "#{url.scheme}://#{url.normalized_host}"
  end
end
