class TestSitesController < ActionController::Base
  before_action :load_site

  helper_method :script_tag, :content_upgrades_script_tags, :content_upgrade_test_ids

  def show
    clear_cache if params.key?(:fresh)
    @model = StaticScriptModel.new(@site)
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

  def content_upgrade_test_ids
    ContentUpgradeSettings.where('offer_headline like ?', 'Test %').pluck(:content_upgrade_id)
  end

  def content_upgrades_script_tags
    content_upgrades.where.not(id: content_upgrade_test_ids).first&.content_upgrade_script_tag
  end

  def script_tag
    "<script>#{ script_content }</script>"
  end

  def script_content
    RenderStaticScript.new(@site).call
  end
end
