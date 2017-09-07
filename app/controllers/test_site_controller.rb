class TestSiteController < ActionController::Base
  before_action :load_site

  def show
    generate_test_site
    render file: path
  end

  private

  def generate_test_site
    Rails.logger.info "[TestSite] Generating static test site for Site##{ @site.id }"
    clear_cache if params[:fresh]
    GenerateTestSite.new(@site.id, full_path: path).call
  end

  def path
    if params[:path].present?
      Rails.root.join(params[:path])
    else
      Rails.root.join('tmp', 'test_site.html')
    end
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
