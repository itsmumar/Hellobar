module SiteElementEditorHelper
  def render_interstitial?
    return false if [
      params[:element_to_copy_id],
      params[:skip_interstitial],
      get_ab_variation("Forced Email Path 2016-03-28") == 'force'
    ].any?

    true
  end
end