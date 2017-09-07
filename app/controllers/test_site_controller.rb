class TestSiteController < ActionController::Base
  before_action :load_site

  def show
    render file: generate_test_site
  end

  private

  def generate_test_site
    Rails.logger.info "[TestSite] Generating static test site for Site##{ @site.id }"
    clear_cache if params[:fresh]
    GenerateTestSite.new(@site.id).call
  end

  def load_site
    @site =
      if params[:id]
        Site.find(params[:id])
      else
        Site.order(updated_at: :desc).first
      end
  end

  def clear_cache
    @site.update_column :updated_at, Time.current
  end
end
