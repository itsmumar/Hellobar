module SiteElementEditorHelper
  def skip_interstitial?
    [
      params[:element_to_copy_id],
      params[:skip_interstitial]
    ].any?
  end
end
