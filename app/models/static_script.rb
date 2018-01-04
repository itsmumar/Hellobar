class StaticScript
  SCRIPTS_LOCAL_FOLDER = '/generated_scripts/'.freeze

  attr_reader :site

  def self.hash_content
    {
      prefix: 'bar',
      suffix: 'cat'
    }
  end

  def self.hash_id(id)
    Digest::SHA1.hexdigest(hash_content[:prefix] + id.to_s + hash_content[:suffix])
  end

  def initialize(site)
    @site = site
  end

  def hashed_id
    StaticScript.hash_id(site.id)
  end

  def name
    "#{ hashed_id }.js"
  end

  def url
    cdn_url_for name
  end

  def modules_url
    cdn_url_for StaticScriptAssets.digest_path('modules.js')
  end

  def installed?
    site.script_installed_at.present? &&
      (site.script_uninstalled_at.blank? ||
        site.script_installed_at > site.script_uninstalled_at)
  end

  def generate
    GenerateStaticScriptJob.perform_later site
  end

  def destroy
    GenerateAndStoreStaticScript.new(site, script_content: '').call
  end

  private

  def cdn_url_for(path)
    File.join(cdn_domain, path)
  end

  def cdn_domain
    if Settings.store_site_scripts_locally
      SCRIPTS_LOCAL_FOLDER
    elsif Settings.script_cdn_url.present?
      "https://#{ Settings.script_cdn_url }"
    else
      raise 'Settings.script_cdn_url or Settings.store_site_scripts_locally must be set'
    end
  end
end
