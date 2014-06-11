class Site < ActiveRecord::Base
  include GuaranteedQueue::Delay

  has_many :rule_sets
  has_many :bars, through: :rule_sets
  has_many :site_memberships, dependent: :destroy
  has_many :users, through: :site_memberships

  before_validation :standardize_url

  after_commit :generate_script
  before_destroy :blank_out_script

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

  def generate_script
    delay :generate_static_assets
  end

  def blank_out_script
    delay :generate_blank_static_assets
  end


  private

  def generate_static_assets(options = {})
    update_attribute(:script_attempted_to_generate_at, Time.now)

    Timeout::timeout(20) do
      generated_script_content = options[:script_content] || script_content(true)
      Hello::AssetStorage.new.create_or_update_file_with_contents(script_name, generated_script_content)
    end

    update_attribute(:script_generated_at, Time.now)
  end

  def generate_blank_static_assets
    generate_static_assets(:script_content => "")
  end

  def standardize_url
    url = Addressable::URI.heuristic_parse(self.url)

    self.url = "#{url.scheme}://#{url.normalized_host}"
  end
end
