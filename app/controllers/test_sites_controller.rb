class TestSitesController < ActionController::Base
  before_action :load_site

  helper_method :script_tag, :content_upgrades_script_tags, :content_upgrade_tests

  def show
    clear_cache if params.key?(:fresh)
    Rails.logger.info "[TestSite] Generating static test site for Site##{ @site.id }"
    render :show
  end

  private

  def load_site
    @site =
      if params[:id]
        Site.find(params[:id])
      else
        Site.order(updated_at: :desc).first
      end
  end

  def clear_cache
    Rails.logger.info '[TestSite] Clearing cache...'
    @site.update_column :updated_at, Time.current
  end

  def content_upgrades
    @site.site_elements.active_content_upgrades
  end

  def content_upgrade_tests
    content_upgrades.where('offer_headline like ?', 'Test %')
  end

  def content_upgrades_script_tags
    content_upgrades.where.not('offer_headline like ?', 'Test %').first&.content_upgrade_script_tag
  end

  def script_tag
    if Rails.env.development?
      GenerateAndStoreStaticScript.new(@site, path: 'test_site.js').call
      '<script src="/generated_scripts/test_site.js"></script>'
    else
      "<script>#{ script_content }</script>"
    end
  end

  def script_content
    GenerateStaticScriptModules.new.call
    RenderStaticScript.new(@site).call
  end
end
