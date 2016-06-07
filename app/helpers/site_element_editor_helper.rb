module SiteElementEditorHelper
  def render_interstitial?
    return false if [
      params[:element_to_copy_id],
      params[:skip_interstitial]
    ].any?

    true
  end
end
